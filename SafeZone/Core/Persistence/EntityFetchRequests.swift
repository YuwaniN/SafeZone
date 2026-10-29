import CoreData

extension UserAccountEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<UserAccountEntity> {
        NSFetchRequest<UserAccountEntity>(entityName: "UserAccountEntity")
    }
}

extension SavedLocationEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SavedLocationEntity> {
        NSFetchRequest<SavedLocationEntity>(entityName: "SavedLocationEntity")
    }
}

extension IncidentReportEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<IncidentReportEntity> {
        NSFetchRequest<IncidentReportEntity>(entityName: "IncidentReportEntity")
    }
}

extension RiskSnapshotEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<RiskSnapshotEntity> {
        NSFetchRequest<RiskSnapshotEntity>(entityName: "RiskSnapshotEntity")
    }
}

extension AlertRecordEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<AlertRecordEntity> {
        NSFetchRequest<AlertRecordEntity>(entityName: "AlertRecordEntity")
    }
}
