extends Reference
class_name IosResolutions

# TODO: Our only iOS data point (iPhone XR) has a 10% error in the reported
#       screen size compared to the actual screen size. But, this is probably
#       close enough for our current purposes.
#   - 6.06'' actual (diagonal)
#   - 5.48717706322'' reported (diagonal)
#   - 5.48717706322/6.06 = 0.9054747629

const DEFAULT_PPI := 300

const IPHONE_SUFFIX_AND_PPIS := [
    {
        suffix = "12 Pro Max",
        ppi = 458,
    },
    {
        suffix = "12 Pro",
        ppi = 460,
    },
    {
        suffix = "12 mini",
        ppi = 476,
    },
    {
        suffix = "12",
        ppi = 460,
    },
    {
        suffix = "SE 2",
        ppi = 326,
    },
    {
        suffix = "11 Pro Max",
        ppi = 458,
    },
    {
        suffix = "11 Pro",
        ppi = 458,
    },
    {
        suffix = "11",
        ppi = 326,
    },
    {
        suffix = "XR",
        ppi = 326,
    },
    {
        suffix = "XS Max",
        ppi = 458,
    },
    {
        suffix = "XS",
        ppi = 458,
    },
    {
        suffix = "X",
        ppi = 458,
    },
    {
        suffix = "8 Plus",
        ppi = 401,
    },
    {
        suffix = "8",
        ppi = 326,
    },
    {
        suffix = "7 Plus",
        ppi = 401,
    },
    {
        suffix = "7",
        ppi = 326,
    },
    {
        suffix = "SE",
        ppi = 326,
    },
    {
        suffix = "6s Plus",
        ppi = 401,
    },
    {
        suffix = "6s",
        ppi = 326,
    },
    {
        suffix = "6 Plus",
        ppi = 401,
    },
    {
        suffix = "6",
        ppi = 326,
    },
    {
        suffix = "5c",
        ppi = 326,
    },
    {
        suffix = "5s",
        ppi = 326,
    },
    {
        suffix = "5",
        ppi = 326,
    },
    {
        suffix = "4S",
        ppi = 326,
    },
    {
        suffix = "4",
        ppi = 326,
    },
    {
        suffix = "3GS",
        ppi = 163,
    },
    {
        suffix = "3G",
        ppi = 163,
    },
    {
        suffix = "1",
        ppi = 163,
    },
    {
        # This is just the PPI for the latest model. This case will probably
        # get hit mostly when future models come out.
        suffix = "",
        ppi = 460,
    },
]

const IPAD_SUFFIX_AND_PPIS = [
    {
        suffix = "Pro 4",
        ppi = 264,
    },
    {
        suffix = "7",
        ppi = 264,
    },
    {
        suffix = "Mini 5",
        ppi = 326,
    },
    {
        suffix = "Air 3",
        ppi = 264,
    },
    {
        suffix = "Pro 3",
        ppi = 264,
    },
    {
        suffix = "6",
        ppi = 264,
    },
    {
        suffix = "Pro 2",
        ppi = 264,
    },
    {
        suffix = "5",
        ppi = 264,
    },
    {
        suffix = "Pro",
        ppi = 264,
    },
    {
        suffix = "mini 4",
        ppi = 326,
    },
    {
        suffix = "Air 2",
        ppi = 326,
    },
    {
        suffix = "mini 3",
        ppi = 264,
    },
    {
        suffix = "mini 2",
        ppi = 326,
    },
    {
        suffix = "Air",
        ppi = 264,
    },
    {
        suffix = "4",
        ppi = 264,
    },
    {
        suffix = "mini",
        ppi = 163,
    },
    {
        suffix = "3",
        ppi = 264,
    },
    {
        suffix = "2",
        ppi = 132,
    },
    {
        suffix = "1",
        ppi = 132,
    },
    {
        # This is just the PPI for the latest model. This case will probably
        # get hit mostly when future models come out.
        suffix = "",
        ppi = 264,
    },
]

const IPOD_SUFFIX_AND_PPIS = [
    {
        suffix = "6",
        ppi = 326,
    },
    {
        suffix = "5",
        ppi = 326,
    },
    {
        suffix = "4",
        ppi = 326,
    },
    {
        suffix = "3",
        ppi = 163,
    },
    {
        suffix = "2",
        ppi = 163,
    },
    {
        suffix = "1",
        ppi = 163,
    },
    {
        # This is just the PPI for the latest model. This case will probably
        # get hit mostly when future models come out.
        suffix = "",
        ppi = 326,
    },
]

func _init() -> void:
    print("IosResolutions._init")

func get_screen_ppi(ios_model_names: IosModelNames) -> int:
    assert(Gs.utils.get_is_ios_device())
    
    var model_name := ios_model_names.get_model_name().to_lower()
    var is_iphone := model_name.find("iphone") >= 0
    var is_ipad := model_name.find("ipad") >= 0
    var is_ipod := model_name.find("ipod") >= 0
    
    var suffix_and_ppis: Array
    if is_iphone:
        suffix_and_ppis = IPHONE_SUFFIX_AND_PPIS
    elif is_ipad:
        suffix_and_ppis = IPAD_SUFFIX_AND_PPIS
    elif is_ipod:
        suffix_and_ppis = IPOD_SUFFIX_AND_PPIS
    else:
        Gs.utils.error()
    
    var ppi := DEFAULT_PPI
    for suffix_and_ppi in suffix_and_ppis:
        var is_a_match := true
        for suffix_token in suffix_and_ppi.suffix.to_lower().split(" "):
            if model_name.find(suffix_token) < 0:
                is_a_match = false
                break
        if is_a_match:
            ppi = suffix_and_ppi.ppi
            break
    assert(ppi != INF)
    
    return ppi
