import QtQuick 2.15

ListModel { // Root element
    id: item
    ListElement {
        //parameters for A/B/X/Y
        //Shift of 5 pixels from Left X for xbox elite 2 series
        //As A
        padAWidth : 69;
        padAHeight : 70;
        padATopY: 382;
        padALeftX: 700; //initial value: 695;

        //As B
        padBWidth : 65;
        padBHeight : 68;
        padBTopY: 321;
        padBLeftX: 766; //initial value: 761;

        //As X
        padXWidth : 66;
        padXHeight : 68;
        padXTopY: 316;
        padXLeftX: 636; //initial value: 631;

        //As Y
        padYWidth : 66;
        padYHeight : 68;
        padYTopY: 253;
        padYLeftX: 700; //695;

    }
}
