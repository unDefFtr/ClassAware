package com.example.classaware

import android.content.ComponentName
import android.content.Context

/**
 * AppFilter - 参考Lawnchair启动器的应用过滤机制
 * 实现多层过滤策略，确保只显示用户真正需要的应用
 */
class AppFilter(private val context: Context) {
    
    companion object {
        // 预定义的过滤组件列表 - 参考Lawnchair的filtered_components配置
        private val FILTERED_COMPONENTS = setOf(
            // Google Voice Search
            "com.google.android.googlequicksearchbox/.VoiceSearchActivity",
            // Google Now Launcher
            "com.google.android.launcher/.StubApp", 
            // Action Services
            "com.google.android.as/com.google.android.apps.miphone.aiai.allapps.main.MainDummyActivity",
            // System UI components
            "com.android.systemui/.recents.RecentsActivity",
            "com.android.systemui/.stackdivider.ForcedResizableInfoActivity",
            "com.android.systemui/.pip.PipMenuActivity",
            "com.android.systemui/.SlicePermissionActivity",
            // Settings Intelligence
            "com.android.settings.intelligence/.modules.battery.BatteryHeaderActivity",
            "com.android.settings.intelligence/.search.SearchActivity",
            // Shell components
            "com.android.shell/.BugreportWarningActivity",
            "com.android.shell/.HeapDumpActivity",
            // External Storage
            "com.android.externalstorage/.MtpDocumentsService",
            // Downloads UI
            "com.android.providers.downloads.ui/.DownloadList",
            // Documents UI
            "com.android.documentsui/.LauncherActivity",
            "com.android.documentsui/.picker.PickActivity",
            // Bluetooth
            "com.android.bluetooth/.opp.BluetoothOppLauncherActivity",
            "com.android.bluetooth/.pbap.BluetoothPbapActivity",
            // NFC
            "com.android.nfc/.NfcRootActivity",
            "com.android.nfc/.BeamShareActivity",
            // Wallpaper
            "com.android.wallpaper.livepicker/.LiveWallpaperActivity",
            "com.android.wallpaper.livepicker/.LiveWallpaperPreview",
            // Input Method
            "com.android.inputmethod.latin/.setup.SetupActivity",
            "com.android.inputmethod.latin/.spellcheck.AndroidSpellCheckerService",
            // Captive Portal
            "com.android.captiveportallogin/.CaptivePortalLoginActivity",
            // Package Installer
            "com.android.packageinstaller/.permission.ui.GrantPermissionsActivity",
            "com.android.packageinstaller/.UninstallerActivity",
            // Keychain
            "com.android.keychain/.KeyChainActivity",
            // Backup
            "com.android.backupconfirm/.BackupRestoreConfirmation",
            // Shared Storage Backup
            "com.android.sharedstoragebackup/.SharedStorageBackup"
        )
        
        // 包名级别的黑名单 - 系统级组件包
        private val BLACKLISTED_PACKAGES = setOf(
            "com.android.systemui",
            "com.android.settings.intelligence",
            "com.android.shell", 
            "com.android.externalstorage",
            "com.android.providers.downloads.ui",
            "com.android.documentsui",
            "com.android.bluetooth",
            "com.android.nfc",
            "com.android.wallpaper.livepicker",
            "com.android.inputmethod.latin",
            "com.android.captiveportallogin",
            "com.android.keychain",
            "com.android.pacprocessor",
            "com.android.proxyhandler",
            "com.android.backupconfirm",
            "com.android.sharedstoragebackup",
            "com.android.printspooler",
            "com.android.statementservice",
            "com.android.companiondevicemanager",
            "com.android.mms.service",
            "com.android.cellbroadcastreceiver"
        )
    }
    
    /**
     * 检查应用是否应该显示 - 参考Lawnchair的shouldShowApp逻辑
     * @param componentName 应用组件名
     * @return true表示应该显示，false表示应该过滤
     */
    fun shouldShowApp(componentName: ComponentName): Boolean {
        val flattenedName = componentName.flattenToString()
        val packageName = componentName.packageName
        
        // 第一层过滤：检查组件名是否在过滤列表中
        if (FILTERED_COMPONENTS.contains(flattenedName)) {
            return false
        }
        
        // 第二层过滤：检查包名是否在黑名单中
        if (BLACKLISTED_PACKAGES.contains(packageName)) {
            return false
        }
        
        // 第三层过滤：检查是否为系统内部组件
        if (isSystemInternalComponent(componentName)) {
            return false
        }
        
        return true
    }
    
    /**
     * 检查是否为系统内部组件
     */
    private fun isSystemInternalComponent(componentName: ComponentName): Boolean {
        val packageName = componentName.packageName
        val className = componentName.className
        
        // 过滤以"."开头的内部Activity（通常是系统内部组件）
        if (className.startsWith("${packageName}.") && className.contains("Internal")) {
            return true
        }
        
        // 过滤测试相关的Activity
        if (className.contains("Test") || className.contains("Debug")) {
            return true
        }
        
        // 过滤设置相关的内部Activity
        if (className.contains("Settings") && packageName.startsWith("com.android")) {
            return true
        }
        
        return false
    }
    
    /**
     * 获取过滤统计信息
     */
    fun getFilterStats(): Map<String, Int> {
        return mapOf(
            "filteredComponents" to FILTERED_COMPONENTS.size,
            "blacklistedPackages" to BLACKLISTED_PACKAGES.size
        )
    }
}