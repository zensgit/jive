package com.jive.app

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.lang.reflect.Proxy

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.jive.app/stream"
    private val METHOD_CHANNEL = "com.jive.app/methods"
    private val SPEECH_CHANNEL = "com.jive.app/speech"
    private val SPEECH_PERMISSION_REQUEST = 3001
    private enum class SpeechMode { RECOGNIZE_ONCE, PRESS_TO_TALK }
    private enum class SpeechEngineType { SYSTEM, BAIDU }
    private companion object {
        private const val BAIDU_VAD_TOUCH = "touch"
        private const val BAIDU_VAD_DNN = "dnn"
        private const val BAIDU_EVENT_ASR_START = "asr.start"
        private const val BAIDU_EVENT_ASR_STOP = "asr.stop"
        private const val BAIDU_EVENT_ASR_CANCEL = "asr.cancel"
        private const val BAIDU_EVENT_ASR_PARTIAL = "asr.partial"
        private const val BAIDU_EVENT_ASR_FINISH = "asr.finish"
        private const val BAIDU_EVENT_ASR_EXIT = "asr.exit"
    }
    private var eventSink: EventChannel.EventSink? = null
    private var pendingEvent: Map<String, Any?>? = null
    private var speechResult: MethodChannel.Result? = null
    private var stopResult: MethodChannel.Result? = null
    private var cachedStopPayload: HashMap<String, Any?>? = null
    private var speechRecognizer: SpeechRecognizer? = null
    private var pendingLocale: String? = null
    private var pendingPreferOffline = false
    private var isSpeechActive = false
    private var speechMode: SpeechMode? = null
    private var activeEngine: SpeechEngineType? = null
    private var baiduEngine: BaiduSpeechEngine? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Setup EventChannel (Stream)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    pendingEvent?.let { payload ->
                        events?.success(payload)
                        pendingEvent = null
                    }
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )

        // 2. Setup MethodChannel (Function Calls)
        io.flutter.plugin.common.MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Could not open notification settings.", null)
                    }
                }
                "openAccessibilitySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Could not open accessibility settings.", null)
                    }
                }
                "openOverlaySettings" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Could not open overlay settings.", null)
                    }
                }
                "openAppDetails" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Could not open app details.", null)
                    }
                }
                "requestIgnoreBatteryOptimizations" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Could not open battery optimization settings.", null)
                    }
                }
                "getAutoPermissionStatus" -> {
                    val data = mapOf(
                        "notification" to isNotificationAccessEnabled(),
                        "accessibility" to isAccessibilityServiceEnabled(),
                        "overlay" to isOverlayPermissionGranted(),
                        "battery" to isIgnoringBatteryOptimizations()
                    )
                    result.success(data)
                }
                else -> result.notImplemented()
            }
        }

        // 3. Setup Speech MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SPEECH_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "recognizeOnce" -> handleSpeechRecognize(call, result)
                "startListening" -> handleSpeechStart(call, result)
                "stopListening" -> handleSpeechStop(result)
                "cancel" -> cancelSpeech(result)
                else -> result.notImplemented()
            }
        }
    }

    private val transactionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == "com.jive.app.NEW_TRANSACTION") {
                val source = intent.getStringExtra("source")
                val amount = intent.getStringExtra("amount")
                val rawText = intent.getStringExtra("raw_text")
                val type = intent.getStringExtra("type")
                val metadata = intent.getStringExtra("metadata")
                val timestamp = intent.getLongExtra("timestamp", System.currentTimeMillis())
                val packageName = intent.getStringExtra("package_name")

                Log.i("JiveAuto", "Capture: source=$source amount=$amount type=$type ts=$timestamp")

                val data = mapOf(
                    "source" to source,
                    "amount" to amount,
                    "raw_text" to rawText,
                    "type" to type,
                    "metadata" to metadata,
                    "timestamp" to timestamp,
                    "package_name" to packageName
                )

                sendEvent(data)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val filter = IntentFilter("com.jive.app.NEW_TRANSACTION")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val isDebuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
            val flags = if (isDebuggable) {
                Context.RECEIVER_EXPORTED
            } else {
                Context.RECEIVER_NOT_EXPORTED
            }
            registerReceiver(transactionReceiver, filter, flags)
        } else {
            registerReceiver(transactionReceiver, filter)
        }
        maybeHandleAutoDeepLink(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        maybeHandleAutoDeepLink(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(transactionReceiver)
        cleanupSpeechEngine()
    }

    private fun isNotificationAccessEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        ) ?: return false
        return enabled.contains(packageName)
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val serviceId = "${packageName}/${JiveAccessibilityService::class.java.name}"
        return enabled.contains(serviceId)
    }

    private fun isOverlayPermissionGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return true
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }

    private fun maybeHandleAutoDeepLink(intent: Intent?) {
        val uri = intent?.data ?: return
        if (uri.scheme != "jive") return
        val isAuto = uri.host == "auto" || uri.path == "/auto"
        if (!isAuto) return

        val source = uri.getQueryParameter("source") ?: uri.getQueryParameter("app") ?: "Shortcut"
        val amount = uri.getQueryParameter("amount") ?: uri.getQueryParameter("money") ?: "0"
        val rawText =
            uri.getQueryParameter("raw_text")
                ?: uri.getQueryParameter("text")
                ?: uri.getQueryParameter("note")
                ?: ""
        val type = uri.getQueryParameter("type") ?: ""
        val ts = uri.getQueryParameter("timestamp")?.toLongOrNull() ?: System.currentTimeMillis()

        Log.i("JiveAuto", "DeepLink: source=$source amount=$amount type=$type ts=$ts uri=$uri")
        val payload = mapOf(
            "source" to source,
            "amount" to amount,
            "raw_text" to rawText,
            "type" to type,
            "timestamp" to ts
        )
        sendEvent(payload)
    }

    private fun sendEvent(payload: Map<String, Any?>) {
        runOnUiThread {
            val sink = eventSink
            if (sink != null) {
                sink.success(payload)
            } else {
                pendingEvent = payload
            }
        }
    }

    // ── Speech Recognition ──

    private fun parseSpeechEngine(call: MethodCall): SpeechEngineType {
        val args = call.arguments as? Map<*, *>
        val engine = args?.get("engine") as? String
        return if (engine == "baidu") SpeechEngineType.BAIDU else SpeechEngineType.SYSTEM
    }

    private fun handleSpeechRecognize(call: MethodCall, result: MethodChannel.Result) {
        if (speechMode != null || isSpeechActive) {
            result.success(buildSpeechPayload(null, "BUSY", "Speech recognition already in progress."))
            return
        }
        pendingLocale = call.argument<String>("locale")
        pendingPreferOffline = call.argument<Boolean>("preferOffline") == true
        activeEngine = parseSpeechEngine(call)
        speechMode = SpeechMode.RECOGNIZE_ONCE
        cachedStopPayload = null
        speechResult = result
        if (!hasRecordPermission()) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                SPEECH_PERMISSION_REQUEST
            )
            return
        }
        val startError = startActiveSpeech(vadTouch = false)
        if (startError != null) {
            finishSpeech(null, startError)
        }
    }

    private fun handleSpeechStart(call: MethodCall, result: MethodChannel.Result) {
        if (speechMode != null || isSpeechActive) {
            result.success(buildSpeechPayload(null, "BUSY", "Speech recognition already in progress."))
            return
        }
        if (!hasRecordPermission()) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                SPEECH_PERMISSION_REQUEST
            )
            result.success(buildSpeechPayload(null, "NO_PERMISSION"))
            return
        }
        pendingLocale = call.argument<String>("locale")
        pendingPreferOffline = call.argument<Boolean>("preferOffline") == true
        activeEngine = parseSpeechEngine(call)
        speechMode = SpeechMode.PRESS_TO_TALK
        cachedStopPayload = null
        val startError = startActiveSpeech(vadTouch = true)
        if (startError != null) {
            resetSpeechState()
            result.success(buildSpeechPayload(null, startError))
            return
        }
        result.success(buildSpeechPayload(null, null))
    }

    private fun handleSpeechStop(result: MethodChannel.Result) {
        if (speechMode != SpeechMode.PRESS_TO_TALK) {
            result.success(buildSpeechPayload(null, "NO_SESSION"))
            return
        }
        val cached = cachedStopPayload
        if (cached != null) {
            cachedStopPayload = null
            result.success(cached)
            return
        }
        stopResult = result
        val stopError = stopActiveSpeech()
        if (stopError != null) {
            stopResult = null
            result.success(buildSpeechPayload(null, stopError))
            resetSpeechState()
        }
    }

    private fun cancelSpeech(result: MethodChannel.Result) {
        if (!isSpeechActive && speechMode == null) {
            result.success(false)
            return
        }
        cancelActiveSpeech()
        finishSpeech(null, "CANCELLED")
        result.success(true)
    }

    private fun hasRecordPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun startActiveSpeech(vadTouch: Boolean): String? {
        return when (activeEngine) {
            SpeechEngineType.SYSTEM -> startSystemSpeechRecognition()
            SpeechEngineType.BAIDU -> startBaiduSpeechRecognition(vadTouch)
            else -> "NO_ENGINE"
        }
    }

    private fun stopActiveSpeech(): String? {
        return when (activeEngine) {
            SpeechEngineType.SYSTEM -> {
                if (speechRecognizer == null) "NO_SESSION" else {
                    speechRecognizer?.stopListening()
                    null
                }
            }
            SpeechEngineType.BAIDU -> {
                if (baiduEngine == null) "NO_SESSION" else {
                    baiduEngine?.stop()
                    null
                }
            }
            else -> "NO_SESSION"
        }
    }

    private fun cancelActiveSpeech() {
        when (activeEngine) {
            SpeechEngineType.SYSTEM -> speechRecognizer?.cancel()
            SpeechEngineType.BAIDU -> baiduEngine?.cancel()
            else -> {}
        }
    }

    private fun startSystemSpeechRecognition(): String? {
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            return "NO_ENGINE"
        }
        val recognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer = recognizer
        isSpeechActive = true
        recognizer.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {}
            override fun onPartialResults(partialResults: Bundle?) {}
            override fun onEvent(eventType: Int, params: Bundle?) {}

            override fun onError(error: Int) {
                finishSpeech(null, mapSpeechError(error))
            }

            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                finishSpeech(matches?.firstOrNull())
            }
        })

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
            putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, packageName)
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, pendingPreferOffline)
            pendingLocale?.let { locale ->
                if (locale.isNotBlank()) {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
                }
            }
        }
        recognizer.startListening(intent)
        return null
    }

    private fun startBaiduSpeechRecognition(vadTouch: Boolean): String? {
        val config = loadBaiduConfig()
        if (!config.isValid) {
            return "NO_CREDENTIALS"
        }
        val engine = baiduEngine ?: BaiduSpeechEngine()
        baiduEngine = engine
        val vadMode = if (vadTouch) BAIDU_VAD_TOUCH else BAIDU_VAD_DNN
        val startError = engine.start(config, vadMode, if (vadTouch) null else 1000)
        if (startError != null) {
            engine.release()
            return startError
        }
        isSpeechActive = true
        return null
    }

    private fun resetSpeechState() {
        speechMode = null
        pendingLocale = null
        pendingPreferOffline = false
        isSpeechActive = false
        cachedStopPayload = null
        speechResult = null
        stopResult = null
        cleanupSpeechEngine()
    }

    private fun finishSpeech(resultText: String?, errorCode: String? = null, message: String? = null) {
        val mode = speechMode
        val payload = buildSpeechPayload(resultText, errorCode, message)
        speechMode = null
        pendingLocale = null
        pendingPreferOffline = false
        isSpeechActive = false
        cleanupSpeechEngine()
        runOnUiThread {
            when (mode) {
                SpeechMode.PRESS_TO_TALK -> {
                    val result = stopResult
                    stopResult = null
                    if (result != null) {
                        result.success(payload)
                    } else if (errorCode != "CANCELLED") {
                        cachedStopPayload = payload
                    }
                }
                SpeechMode.RECOGNIZE_ONCE -> {
                    val result = speechResult
                    speechResult = null
                    result?.success(payload)
                }
                else -> {}
            }
        }
    }

    private fun cleanupSpeechEngine() {
        speechRecognizer?.destroy()
        speechRecognizer = null
        baiduEngine?.release()
        baiduEngine = null
        activeEngine = null
    }

    private data class BaiduSpeechConfig(
        val appId: String,
        val apiKey: String,
        val secretKey: String
    ) {
        val isValid: Boolean
            get() = appId.isNotBlank() && apiKey.isNotBlank() && secretKey.isNotBlank()
    }

    private fun loadBaiduConfig(): BaiduSpeechConfig {
        return BaiduSpeechConfig("", "", "")
    }

    private inner class BaiduSpeechEngine {
        private var eventManager: Any? = null
        private var eventListener: Any? = null
        private var eventListenerClass: Class<*>? = null
        private var lastResult: String? = null
        private var finished = false

        fun start(config: BaiduSpeechConfig, vadMode: String, vadTimeoutMs: Int?): String? {
            if (!config.isValid) return "NO_CREDENTIALS"
            finished = false
            lastResult = null
            val manager = createEventManager() ?: return "NO_BAIDU_SDK"
            val listener = createListener() ?: return "NO_BAIDU_SDK"
            eventManager = manager
            eventListener = listener
            registerListener(manager, listener)
            val params = JSONObject().apply {
                put("appid", config.appId)
                put("key", config.apiKey)
                put("secret", config.secretKey)
                put("disable-punctuation", true)
                put("accept-audio-volume", false)
                put("vad", vadMode)
                if (vadTimeoutMs != null) {
                    put("vad.endpoint-timeout", vadTimeoutMs)
                }
            }.toString()
            sendBaiduEvent(manager, BAIDU_EVENT_ASR_START, params)
            return null
        }

        fun stop() {
            sendBaiduEvent(eventManager, BAIDU_EVENT_ASR_STOP, null)
        }

        fun cancel() {
            sendBaiduEvent(eventManager, BAIDU_EVENT_ASR_CANCEL, null)
        }

        fun release() {
            val manager = eventManager
            val listener = eventListener
            if (manager != null && listener != null) {
                unregisterListener(manager, listener)
            }
            eventManager = null
            eventListener = null
            eventListenerClass = null
            lastResult = null
            finished = false
        }

        private fun createEventManager(): Any? {
            return try {
                val factoryClass = Class.forName("com.baidu.speech.EventManagerFactory")
                val createMethod = factoryClass.getMethod("create", Context::class.java, String::class.java)
                createMethod.invoke(null, applicationContext, "asr")
            } catch (e: Exception) {
                null
            }
        }

        private fun createListener(): Any? {
            return try {
                val listenerClass = Class.forName("com.baidu.speech.EventListener")
                eventListenerClass = listenerClass
                Proxy.newProxyInstance(
                    listenerClass.classLoader,
                    arrayOf(listenerClass)
                ) { _, method, args ->
                    if (method.name == "onEvent" && args != null && args.isNotEmpty()) {
                        val name = args[0] as? String
                        val params = args.getOrNull(1) as? String
                        handleBaiduEvent(name, params)
                    }
                    null
                }
            } catch (e: Exception) {
                null
            }
        }

        private fun registerListener(manager: Any, listener: Any) {
            val listenerClass = eventListenerClass ?: return
            try {
                val registerMethod = manager.javaClass.getMethod("registerListener", listenerClass)
                registerMethod.invoke(manager, listener)
            } catch (_: Exception) {
            }
        }

        private fun unregisterListener(manager: Any, listener: Any) {
            val listenerClass = eventListenerClass ?: return
            try {
                val unregisterMethod = manager.javaClass.getMethod("unregisterListener", listenerClass)
                unregisterMethod.invoke(manager, listener)
            } catch (_: Exception) {
            }
        }

        private fun sendBaiduEvent(manager: Any?, event: String, params: String?) {
            if (manager == null) return
            try {
                val sendMethod = manager.javaClass.getMethod(
                    "send",
                    String::class.java,
                    String::class.java,
                    ByteArray::class.java,
                    Int::class.javaPrimitiveType,
                    Int::class.javaPrimitiveType
                )
                sendMethod.invoke(manager, event, params, null, 0, 0)
            } catch (_: Exception) {
            }
        }

        private fun handleBaiduEvent(name: String?, params: String?) {
            if (finished || name == null) return
            when (name) {
                BAIDU_EVENT_ASR_PARTIAL -> {
                    val json = parseJson(params) ?: return
                    val resultType = json.optString("result_type")
                    val bestResult = json.optString("best_result")
                    if (bestResult.isNotBlank()) {
                        lastResult = bestResult
                    }
                    if (resultType == "final_result" && bestResult.isNotBlank()) {
                        finished = true
                        finishSpeech(bestResult, null, null)
                    }
                }
                BAIDU_EVENT_ASR_FINISH -> {
                    val json = parseJson(params) ?: return
                    val error = json.optInt("error", 0)
                    if (error != 0) {
                        finished = true
                        val desc = json.optString("desc", json.optString("error_desc"))
                        finishSpeech(null, "BAIDU_ERROR_$error", desc.takeIf { it.isNotBlank() })
                    }
                }
                BAIDU_EVENT_ASR_EXIT -> {
                    if (!finished) {
                        finished = true
                        val finalText = lastResult?.takeIf { it.isNotBlank() }
                        finishSpeech(finalText, if (finalText == null) "NO_MATCH" else null)
                    }
                }
            }
        }

        private fun parseJson(raw: String?): JSONObject? {
            if (raw.isNullOrBlank()) return null
            return try {
                JSONObject(raw)
            } catch (e: Exception) {
                null
            }
        }
    }

    private fun mapSpeechError(error: Int): String {
        return when (error) {
            SpeechRecognizer.ERROR_AUDIO -> "AUDIO"
            SpeechRecognizer.ERROR_CLIENT -> "CLIENT"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "NO_PERMISSION"
            SpeechRecognizer.ERROR_NETWORK,
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "NO_NETWORK"
            SpeechRecognizer.ERROR_NO_MATCH -> "NO_MATCH"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "BUSY"
            SpeechRecognizer.ERROR_SERVER -> "SERVER"
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "TIMEOUT"
            SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED,
            SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> "NO_ENGINE"
            else -> "UNKNOWN"
        }
    }

    private fun buildSpeechPayload(
        text: String?,
        errorCode: String?,
        message: String? = null
    ): HashMap<String, Any?> {
        val payload = HashMap<String, Any?>()
        payload["text"] = text
        if (errorCode != null) {
            payload["error"] = errorCode
        }
        if (message != null) {
            payload["message"] = message
        }
        return payload
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != SPEECH_PERMISSION_REQUEST) return
        if (speechMode != SpeechMode.RECOGNIZE_ONCE || speechResult == null) return
        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            val startError = startActiveSpeech(vadTouch = false)
            if (startError != null) {
                finishSpeech(null, startError)
            }
        } else {
            finishSpeech(null, "NO_PERMISSION")
        }
    }
}
