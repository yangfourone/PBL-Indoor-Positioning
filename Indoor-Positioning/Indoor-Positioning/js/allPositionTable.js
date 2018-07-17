// TODO 方法：位置資訊(電資一樓)
function EE01Position(posi)
{
    switch(posi)
    {
        case "1":
        {
            $.fixPredictPosi="EE1F hall"; // "EE1F大廳";
            $.go_x=120; $.go_y=660;
            break;
        }

        case "2":
        {
            $.fixPredictPosi="EE1F corridor1(near by hall)"; // "EE1F走廊前段(靠大廳)";
            $.go_x=220; $.go_y=570;
            break;
        }

        case "3":
        {
            $.fixPredictPosi="EE1F corridor2"; // "EE1F走廊中段";
            $.go_x=220; $.go_y=370;
            break;
        }

        case "4":
        {
            $.fixPredictPosi="EE1F corridor3(near by elevator)"; // "EE1F走廊後段(靠電梯)";
            $.go_x=220; $.go_y=200;
            break;
        }

        case "5":
        {
            $.fixPredictPosi="EE1F Plaza in front of elevator"; // "EE1F電梯";
            $.go_x=180; $.go_y=50;
            break;
        }
    }
}

// TODO 方法：位置資訊(國際一樓)
function IB01Position(posi)
{
    switch(posi)
    {
        case "1":
        {
            $.fixPredictPosi="IB1F place1";
            $.go_x=225; $.go_y=105;
            break;
        }

        case "2":
        {
            $.fixPredictPosi="IB1F place2";
            $.go_x=225; $.go_y=185;
            break;
        }

        case "100":
        {
            $.fixPredictPosi="IB1F place3";
            $.go_x=140; $.go_y=25;
            break;
        }

        case "101":
        {
            $.fixPredictPosi="IB1F place4";
            $.go_x=185; $.go_y=105;
            break;
        }

        case "102":
        {
            $.fixPredictPosi="IB1F place5";
            $.go_x=185; $.go_y=215;
            break;
        }

        case "103":
        {
            $.fixPredictPosi="IB1F place6";
            $.go_x=185; $.go_y=295;
            break;
        }

        case "104":
        {
            $.fixPredictPosi="IB1F place7";
            $.go_x=175; $.go_y=380;
            break;
        }

        case "204":
        {
            $.fixPredictPosi="IB1F place8";
            $.go_x=115; $.go_y=380;
            break;
        }

        case "304":
        {
            $.fixPredictPosi="IB1F place9";
            $.go_x=35; $.go_y=375;
            break;
        }
    }
}

// TODO 方法：位置資訊(國際十一樓)
function IB11Position(posi)
{
    switch(posi)
    {
        case "1":
        {
            $.fixPredictPosi="IB11F place1";
            $.go_x=140; $.go_y=80;
            break;
        }

        case "2":
        {
            $.fixPredictPosi="IB11F place2";
            $.go_x=90; $.go_y=110;
            break;
        }

        case "3":
        {
            $.fixPredictPosi="IB11F place3";
            $.go_x=55; $.go_y=185;
            break;
        }
    }
}

// TODO 方法：商場推播內容(電資一樓)
function showInfoToUser(posi)
{
    switch(posi)
    {
        case "1": { swal("EE1F大廳", "這裡是電資學院一樓的大廳，提供著許多座椅讓學生們休息與空間討論。"); break; }
        case "2": { swal("EE1F走廊前段(靠大廳)", "這裡是電資學院一樓靠近大廳的走廊。"); break; }
        case "3": { swal("EE1F走廊中段", "這裡是電資學院一樓的走廊中段。"); break; }
        case "4": { swal("EE1F走廊後段(靠電梯)", "這裡是電資學院一樓靠近電梯的走廊。"); break; }
        case "5": { swal("EE1F電梯", "這裡是電資學院一樓的電梯，提供著許多活動、比賽資訊給路過的學生們參考。"); break; }
    }
}