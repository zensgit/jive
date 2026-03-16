# Data Backup Roundtrip Regression MVP

## 目标

验证 `JiveDataBackupService` 的导出/导入主闭环，避免上线测试阶段出现“能导出、不能恢复”或“恢复后字段丢失”。

## 覆盖范围

- account
- category
- tag
- transaction
- import job

## 校验点

- 导出文件成功生成到 documents 目录
- 导入 summary 计数正确
- 清空后恢复数据字段保真
- `clearBefore` 路径可用

## 对应文件

- 测试：`/Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_roundtrip_test.dart`
- 服务：`/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/data_backup_service.dart`
