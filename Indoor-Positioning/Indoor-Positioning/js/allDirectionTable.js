// TODO 方法：導航資訊(電資一樓)
function EE01Direction(from)
{
    switch(from)
    {
        case "1":
        {
            $.fixPredictPosi="EE1F hall"; // "EE1F大廳";
            return from="c2";
        }

        case "2":
        {
            $.fixPredictPosi="EE1F corridor1(near by hall)"; // "EE1F走廊前段(靠大廳)";
            return from="a4";
        }

        case "3":
        {
            $.fixPredictPosi="EE1F corridor2"; // "EE1F走廊中段";
            return from="a7";
        }

        case "4":
        {
            $.fixPredictPosi="EE1F corridor3(near by elevator)"; // "EE1F走廊後段(靠電梯)";
            return from="a11";
        }

        case "5":
        {
            $.fixPredictPosi="EE1F Plaza in front of elevator"; // "EE1F電梯";
            return from="b14";
        }
    }
}

// TODO 方法：導航資訊(國際一樓)
function IB01Direction(from)
{
    return from;
}

// TODO 方法：導航資訊(國際十一樓)
function IB11Direction(from)
{
    return from;
}