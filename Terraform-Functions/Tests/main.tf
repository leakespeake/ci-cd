locals {
    string-owner    = "barry"
    string-env      = "dev"
    string-app      = "weather-app"

    num1 = 01
    num2 = 02
    num3 = 03

    list1 = ["hemel", "slough", "athena"]

    map1 = {
        hhe = "vc.hhe.twonk.com"
        slu = "vc.slu.twonk.com"
        ath = "vc.ath.twonk.com"
    }

    map-of-lists1 = {
    slu = ["10.92.173.40", "10.92.173.41", "10.76.173.40"]
    hhe = ["10.76.173.40", "10.76.173.41", "10.92.173.40"]
    ath = ["10.64.70.40", "10.64.70.41", "10.64.70.42"]
    }

    env = {
        hhe = "hhe"
        slu = "slu"
        ath = "ath"
    }

}