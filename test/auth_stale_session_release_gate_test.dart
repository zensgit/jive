import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/service/credential_bundle_lease_governance_service.dart';
import 'package:jive/core/service/credential_bundle_version_reconciliation_governance_service.dart';
import 'package:jive/core/service/email_credential_bundle_consistency_governance_service.dart';
import 'package:jive/core/service/password_modify_response_integrity_governance_service.dart';

void main() {
  final leaseService = CredentialBundleLeaseGovernanceService();
  final versionService =
      CredentialBundleVersionReconciliationGovernanceService();
  final passwordService = PasswordModifyResponseIntegrityGovernanceService();
  final emailService = EmailCredentialBundleConsistencyGovernanceService();

  test('release gate reviews stale callback writes that were not blocked', () {
    final leaseResult = leaseService.evaluate(
      _leaseInput(
        action: CredentialBundleLeaseAction.blockStaleCallbackWrite,
        staleCallbackDetected: true,
        staleCallbackWriteBlocked: false,
      ),
    );

    expect(leaseResult.status, CredentialBundleLeaseStatus.review);
    expect(leaseResult.reason, contains('stale callback'));
  });

  test('release gate reviews stale bundle invalidation gaps', () {
    final versionResult = versionService.evaluate(
      _versionInput(
        action:
            CredentialBundleVersionReconciliationAction.invalidateStaleBundle,
        staleBundleDetected: true,
        staleBundleInvalidated: false,
      ),
    );

    expect(
      versionResult.status,
      CredentialBundleVersionReconciliationStatus.review,
    );
    expect(versionResult.reason, contains('陈旧凭据包'));
  });

  test('release gate catches missing token rotation after password modify', () {
    final versionResult = versionService.evaluate(
      _versionInput(
        action: CredentialBundleVersionReconciliationAction.rotateSessionToken,
        tokenRotationRequired: true,
        tokenRotated: false,
      ),
    );
    final passwordResult = passwordService.evaluate(
      _passwordInput(
        action: PasswordModifyResponseIntegrityAction.reconcileSessionToken,
        shouldUpdateVerifyToken: true,
        storedSessionTokenUpdated: false,
      ),
    );

    expect(
      versionResult.status,
      CredentialBundleVersionReconciliationStatus.review,
    );
    expect(versionResult.reason, contains('token rotation'));
    expect(passwordResult.status, PasswordModifyResponseIntegrityStatus.review);
    expect(passwordResult.reason, contains('session token'));
  });

  test(
    'release gate keeps healthy email and session bundles on the ready path',
    () {
      final leaseResult = leaseService.evaluate(_leaseInput());
      final versionResult = versionService.evaluate(_versionInput());
      final passwordResult = passwordService.evaluate(_passwordInput());
      final emailResult = emailService.evaluate(_emailInput());

      expect(leaseResult.status, CredentialBundleLeaseStatus.ready);
      expect(
        versionResult.status,
        CredentialBundleVersionReconciliationStatus.ready,
      );
      expect(
        passwordResult.status,
        PasswordModifyResponseIntegrityStatus.ready,
      );
      expect(emailResult.status, EmailCredentialBundleConsistencyStatus.ready);
    },
  );
}

CredentialBundleLeaseGovernanceInput _leaseInput({
  CredentialBundleLeaseAction action =
      CredentialBundleLeaseAction.reconcileLeaseOnAuthSuccess,
  bool authSuccess = true,
  bool leasePresent = true,
  bool leaseExpired = false,
  bool leaseRenewed = true,
  bool tokenUpdated = true,
  bool leaseRenewedAfterTokenUpdate = true,
  bool staleCallbackDetected = false,
  bool staleCallbackWriteBlocked = true,
  bool sessionVersionChanged = true,
  bool sessionVersionBroadcastRequired = true,
  bool sessionVersionBroadcasted = true,
  bool crossTabAckCompleted = true,
  bool bundleVersionAligned = true,
  bool navigationFinished = true,
}) {
  return CredentialBundleLeaseGovernanceInput(
    action: action,
    authSuccess: authSuccess,
    leasePresent: leasePresent,
    leaseExpired: leaseExpired,
    leaseRenewed: leaseRenewed,
    tokenUpdated: tokenUpdated,
    leaseRenewedAfterTokenUpdate: leaseRenewedAfterTokenUpdate,
    staleCallbackDetected: staleCallbackDetected,
    staleCallbackWriteBlocked: staleCallbackWriteBlocked,
    sessionVersionChanged: sessionVersionChanged,
    sessionVersionBroadcastRequired: sessionVersionBroadcastRequired,
    sessionVersionBroadcasted: sessionVersionBroadcasted,
    crossTabAckCompleted: crossTabAckCompleted,
    bundleVersionAligned: bundleVersionAligned,
    navigationFinished: navigationFinished,
  );
}

CredentialBundleVersionReconciliationGovernanceInput _versionInput({
  CredentialBundleVersionReconciliationAction action =
      CredentialBundleVersionReconciliationAction.reconcileBundleVersion,
  bool responseSuccess = true,
  bool bundleVersionPresent = true,
  bool bundleVersionMatched = true,
  bool credentialVersionMatched = true,
  bool tokenRotationRequired = false,
  bool tokenRotated = true,
  bool staleBundleDetected = false,
  bool staleBundleInvalidated = true,
  bool partialCredentialWriteDetected = false,
  bool partialCredentialWriteRecovered = true,
  bool sessionFanoutRequired = true,
  bool sessionFanoutCompleted = true,
  bool userSnapshotMerged = true,
  bool emailCacheAligned = true,
  bool navigationFinished = true,
}) {
  return CredentialBundleVersionReconciliationGovernanceInput(
    action: action,
    responseSuccess: responseSuccess,
    bundleVersionPresent: bundleVersionPresent,
    bundleVersionMatched: bundleVersionMatched,
    credentialVersionMatched: credentialVersionMatched,
    tokenRotationRequired: tokenRotationRequired,
    tokenRotated: tokenRotated,
    staleBundleDetected: staleBundleDetected,
    staleBundleInvalidated: staleBundleInvalidated,
    partialCredentialWriteDetected: partialCredentialWriteDetected,
    partialCredentialWriteRecovered: partialCredentialWriteRecovered,
    sessionFanoutRequired: sessionFanoutRequired,
    sessionFanoutCompleted: sessionFanoutCompleted,
    userSnapshotMerged: userSnapshotMerged,
    emailCacheAligned: emailCacheAligned,
    navigationFinished: navigationFinished,
  );
}

PasswordModifyResponseIntegrityGovernanceInput _passwordInput({
  PasswordModifyResponseIntegrityAction action =
      PasswordModifyResponseIntegrityAction.clearStaleSessionArtifacts,
  bool responseSuccess = true,
  bool expectUserPayload = true,
  bool responseUserPresent = true,
  bool expectVerifyToken = true,
  bool responseTokenPresent = true,
  bool shouldUpdateVerifyToken = true,
  bool storedSessionTokenUpdated = true,
  bool shouldUpdateStoredCredential = true,
  bool storedCredentialUpdated = true,
  bool shouldUpdateStoredEmail = true,
  bool storedEmailUpdated = true,
  bool shouldPersistUserSnapshot = true,
  bool persistedUserSnapshot = true,
  bool shouldMergeWithCurrentUser = true,
  bool mergedWithCurrentUser = true,
  bool shouldClearStaleSessionArtifacts = true,
  bool staleSessionArtifactsCleared = true,
}) {
  return PasswordModifyResponseIntegrityGovernanceInput(
    action: action,
    responseSuccess: responseSuccess,
    expectUserPayload: expectUserPayload,
    responseUserPresent: responseUserPresent,
    expectVerifyToken: expectVerifyToken,
    responseTokenPresent: responseTokenPresent,
    shouldUpdateVerifyToken: shouldUpdateVerifyToken,
    storedSessionTokenUpdated: storedSessionTokenUpdated,
    shouldUpdateStoredCredential: shouldUpdateStoredCredential,
    storedCredentialUpdated: storedCredentialUpdated,
    shouldUpdateStoredEmail: shouldUpdateStoredEmail,
    storedEmailUpdated: storedEmailUpdated,
    shouldPersistUserSnapshot: shouldPersistUserSnapshot,
    persistedUserSnapshot: persistedUserSnapshot,
    shouldMergeWithCurrentUser: shouldMergeWithCurrentUser,
    mergedWithCurrentUser: mergedWithCurrentUser,
    shouldClearStaleSessionArtifacts: shouldClearStaleSessionArtifacts,
    staleSessionArtifactsCleared: staleSessionArtifactsCleared,
  );
}

EmailCredentialBundleConsistencyGovernanceInput _emailInput({
  EmailCredentialBundleConsistencyAction action =
      EmailCredentialBundleConsistencyAction.clearInconsistentBundle,
  bool responseSuccess = true,
  bool userPayloadPresent = true,
  bool tokenPayloadPresent = true,
  bool emailAvailable = true,
  bool passwordCipherAvailable = true,
  bool shouldPersistEmail = true,
  bool persistedEmail = true,
  bool shouldPersistCredential = true,
  bool persistedCredential = true,
  bool shouldPersistToken = true,
  bool persistedToken = true,
  bool shouldPersistUserSnapshot = true,
  bool persistedUserSnapshot = true,
  bool flowBundleConsistent = true,
  bool credentialRecheckTriggered = true,
  bool inconsistentBundleCleared = true,
  bool navigationFinished = true,
}) {
  return EmailCredentialBundleConsistencyGovernanceInput(
    action: action,
    responseSuccess: responseSuccess,
    userPayloadPresent: userPayloadPresent,
    tokenPayloadPresent: tokenPayloadPresent,
    emailAvailable: emailAvailable,
    passwordCipherAvailable: passwordCipherAvailable,
    shouldPersistEmail: shouldPersistEmail,
    persistedEmail: persistedEmail,
    shouldPersistCredential: shouldPersistCredential,
    persistedCredential: persistedCredential,
    shouldPersistToken: shouldPersistToken,
    persistedToken: persistedToken,
    shouldPersistUserSnapshot: shouldPersistUserSnapshot,
    persistedUserSnapshot: persistedUserSnapshot,
    flowBundleConsistent: flowBundleConsistent,
    credentialRecheckTriggered: credentialRecheckTriggered,
    inconsistentBundleCleared: inconsistentBundleCleared,
    navigationFinished: navigationFinished,
  );
}
