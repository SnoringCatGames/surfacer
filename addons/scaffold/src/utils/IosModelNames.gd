class_name IosModelNames
extends Reference

# This table was found here: https://stackoverflow.com/a/11197770/489568
const DEVICE_MODEL_NUMBER_TO_READABLE_NAME := {
    # Simulator
    "i386": "32-bit Simulator",
    "x86_64": "64-bit Simulator",
    
    # iPhone
    "iPhone1,1": "iPhone",
    "iPhone1,2": "iPhone 3G",
    "iPhone2,1": "iPhone 3GS",
    "iPhone3,1": "iPhone 4 (GSM)",
    "iPhone3,2": "iPhone 4 (GSM Rev A)",
    "iPhone3,3": "iPhone 4 (CDMA/Verizon/Sprint)",
    "iPhone4,1": "iPhone 4S",
    "iPhone5,1": "iPhone 5 (model A1428, AT&T/Canada)",
    "iPhone5,2": "iPhone 5 (model A1429, everything else)",
    "iPhone5,3": "iPhone 5c (model A1456, A1532 | GSM)",
    "iPhone5,4": "iPhone 5c (model A1507, A1516, A1526 (China), A1529 | Global)",
    "iPhone6,1": "iPhone 5s (model A1433, A1533 | GSM)",
    "iPhone6,2": "iPhone 5s (model A1457, A1518, A1528 (China), A1530 | Global)",
    "iPhone7,1": "iPhone 6 Plus",
    "iPhone7,2": "iPhone 6",
    "iPhone8,1": "iPhone 6S",
    "iPhone8,2": "iPhone 6S Plus",
    "iPhone8,4": "iPhone SE",
    "iPhone9,1": "iPhone 7 (CDMA)",
    "iPhone9,3": "iPhone 7 (GSM)",
    "iPhone9,2": "iPhone 7 Plus (CDMA)",
    "iPhone9,4": "iPhone 7 Plus (GSM)",
    "iPhone10,1": "iPhone 8 (CDMA)",
    "iPhone10,4": "iPhone 8 (GSM)",
    "iPhone10,2": "iPhone 8 Plus (CDMA)",
    "iPhone10,5": "iPhone 8 Plus (GSM)",
    "iPhone10,3": "iPhone X (CDMA)",
    "iPhone10,6": "iPhone X (GSM)",
    "iPhone11,2": "iPhone XS",
    "iPhone11,4": "iPhone XS Max",
    "iPhone11,6": "iPhone XS Max China",
    "iPhone11,8": "iPhone XR",
    "iPhone12,1": "iPhone 11",
    "iPhone12,3": "iPhone 11 Pro",
    "iPhone12,5": "iPhone 11 Pro Max",
    "iPhone12,8": "iPhone SE (2nd Gen)",
    
    # iPad 1
    "iPad1,1": "iPad 1 - Wifi (model A1219)",
    "iPad1,2": "iPad 1 - Wifi + Cellular (model A1337)",
    
    # iPad 2
    "iPad2,1": "iPad 2 - Wifi (model A1395)",
    "iPad2,2": "iPad 2 - GSM (model A1396)",
    "iPad2,3": "iPad 2 - 3G (model A1397)",
    "iPad2,4": "iPad 2 - Wifi (model A1395)",
    
    # iPad Mini
    "iPad2,5": "iPad Mini - Wifi (model A1432)",
    "iPad2,6": "iPad Mini - Wifi + Cellular (model  A1454)",
    "iPad2,7": "iPad Mini - Wifi + Cellular (model  A1455)",
    
    # iPad 3
    "iPad3,1": "iPad 3 - Wifi (model A1416)",
    "iPad3,2": "iPad 3 - Wifi + Cellular (model  A1403)",
    "iPad3,3": "iPad 3 - Wifi + Cellular (model  A1430)",
    
    # iPad 4
    "iPad3,4": "iPad 4 - Wifi (model A1458)",
    "iPad3,5": "iPad 4 - Wifi + Cellular (model  A1459)",
    "iPad3,6": "iPad 4 - Wifi + Cellular (model  A1460)",
    
    # iPad AIR
    "iPad4,1": "iPad AIR - Wifi (model A1474)",
    "iPad4,2": "iPad AIR - Wifi + Cellular (model A1475)",
    "iPad4,3": "iPad AIR - Wifi + Cellular (model A1476)",
    
    # iPad Mini 2
    "iPad4,4": "iPad Mini 2 - Wifi (model A1489)",
    "iPad4,5": "iPad Mini 2 - Wifi + Cellular (model A1490)",
    "iPad4,6": "iPad Mini 2 - Wifi + Cellular (model A1491)",
    
    # iPad Mini 3
    "iPad4,7": "iPad Mini 3 - Wifi (model A1599)",
    "iPad4,8": "iPad Mini 3 - Wifi + Cellular (model A1600)",
    "iPad4,9": "iPad Mini 3 - Wifi + Cellular (model A1601)",
    
    # iPad Mini 4
    "iPad5,1": "iPad Mini 4 - Wifi (model A1538)",
    "iPad5,2": "iPad Mini 4 - Wifi + Cellular (model A1550)",
    
    # iPad AIR 2
    "iPad5,3": "iPad AIR 2 - Wifi (model A1566)",
    "iPad5,4": "iPad AIR 2 - Wifi + Cellular (model A1567)",
    
    # iPad PRO 9.7"
    "iPad6,3": "iPad PRO 9.7\" - Wifi (model A1673)",
    "iPad6,4": "iPad PRO 9.7\" - Wifi + Cellular (model A1674, A1675)",
    
    # iPad PRO 12.9"
    "iPad6,7": "iPad PRO 12.9\" - Wifi (model A1584)",
    "iPad6,8": "iPad PRO 12.9\" - Wifi + Cellular (model A1652)",
    
    # iPad (5th generation)
    "iPad6,11": "iPad (5th generation) - Wifi (model A1822)",
    "iPad6,12": "iPad (5th generation) - Wifi + Cellular (model A1823)",
    
    # iPad PRO 12.9" (2nd Gen)
    "iPad7,1": "iPad PRO 12.9\" (2nd Gen) - Wifi (model A1670)",
    "iPad7,2": "iPad PRO 12.9\" (2nd Gen) - Wifi + Cellular (model A1671, A1821)",
    
    # iPad PRO 10.5"
    "iPad7,3": "iPad PRO 10.5\" - Wifi (model A1701)",
    "iPad7,4": "iPad PRO 10.5\" - Wifi + Cellular (model A1709)",
    
    # iPad (6th Gen)
    "iPad7,5": "iPad (6th Gen) - WiFi",
    "iPad7,6": "iPad (6th Gen) - WiFi + Cellular",
    
    # iPad (7th Gen)
    "iPad7,11": "iPad (7th Gen) - WiFi",
    "iPad7,12": "iPad (7th Gen) - WiFi + Cellular",
    
    # iPad PRO 11"
    "iPad8,1": "iPad PRO 11\" - WiFi",
    "iPad8,2": "iPad PRO 11\" - 1TB, WiFi",
    "iPad8,3": "iPad PRO 11\" - WiFi + Cellular",
    "iPad8,4": "iPad PRO 11\" - 1TB, WiFi + Cellular",
    
    # iPad PRO 12.9" (3rd Gen)
    "iPad8,5": "iPad PRO 12.9\" (3rd Gen) - WiFi",
    "iPad8,6": "iPad PRO 12.9\" (3rd Gen) - 1TB, WiFi",
    "iPad8,7": "iPad PRO 12.9\" (3rd Gen) - WiFi + Cellular",
    "iPad8,8": "iPad PRO 12.9\" (3rd Gen) - 1TB, WiFi + Cellular",
    
    # iPad PRO 11" (2nd Gen)
    "iPad8,9": "iPad PRO 11\" (2nd Gen) - WiFi",
    "iPad8,10": "iPad PRO 11\" (2nd Gen) - 1TB, WiFi",
    
    # iPad PRO 12.9" (4th Gen)
    "iPad8,11": "iPad PRO 12.9\" (4th Gen) - (WiFi)",
    "iPad8,12": "iPad PRO 12.9\" (4th Gen) - (WiFi+Cellular)",
    
    # iPad mini 5th Gen
    "iPad11,1": "iPad mini 5th Gen - WiFi",
    "iPad11,2": "iPad mini 5th Gen - Wifi  + Cellular",
    
    # iPad Air 3rd Gen
    "iPad11,3": "iPad Air 3rd Gen - Wifi ",
    "iPad11,4": "iPad Air 3rd Gen - Wifi  + Cellular",
    
    # iPod Touch
    "iPod1,1": "iPod Touch",
    "iPod2,1": "iPod Touch Second Generation",
    "iPod3,1": "iPod Touch Third Generation",
    "iPod4,1": "iPod Touch Fourth Generation",
    "iPod5,1": "iPod Touch 5th Generation",
    "iPod7,1": "iPod Touch 6th Generation",
    "iPod9,1": "iPod Touch 7th Generation",
    
    # Apple Watch
    "Watch1,1": "Apple Watch 38mm case",
    "Watch1,2": "Apple Watch 38mm case",
    "Watch2,6": "Apple Watch Series 1 38mm case",
    "Watch2,7": "Apple Watch Series 1 42mm case",
    "Watch2,3": "Apple Watch Series 2 38mm case",
    "Watch2,4": "Apple Watch Series 2 42mm case",
    "Watch3,1": "Apple Watch Series 3 38mm case (GPS+Cellular)",
    "Watch3,2": "Apple Watch Series 3 42mm case (GPS+Cellular)",
    "Watch3,3": "Apple Watch Series 3 38mm case (GPS)",
    "Watch3,4": "Apple Watch Series 3 42mm case (GPS)",
    "Watch4,1": "Apple Watch Series 4 40mm case (GPS)",
    "Watch4,2": "Apple Watch Series 4 44mm case (GPS)",
    "Watch4,3": "Apple Watch Series 4 40mm case (GPS+Cellular)",
    "Watch4,4": "Apple Watch Series 4 44mm case (GPS+Cellular)",
    "Watch5,1": "Apple Watch Series 5 40mm case (GPS)",
    "Watch5,2": "Apple Watch Series 5 44mm case (GPS)",
    "Watch5,3": "Apple Watch Series 5 40mm case (GPS+Cellular)",
    "Watch5,4": "Apple Watch Series 5 44mm case (GPS+Cellular)",
}

func _init() -> void:
    print("IosModelNames._init")

static func get_model_name() -> String:
    assert(OS.get_name() == "iOS")
    var os_model_name := OS.get_model_name()
    return DEVICE_MODEL_NUMBER_TO_READABLE_NAME[os_model_name] if \
            DEVICE_MODEL_NUMBER_TO_READABLE_NAME.has(os_model_name) else \
            ("%s (unrecognized device number)" % os_model_name)
