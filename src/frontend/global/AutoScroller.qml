import QtQuick 2.12
import QtQuick.VirtualKeyboard 2.15

Item {
    property var flickable;
    property var inputParent;
    property var verticalLimit;
    property var inputItem: InputContext.priv.inputItem

    onInputItemChanged: {
        if (inputItem !== null){
            if(inputItem.parent !== null){
                inputParent = inputItem.parent;
                do{
                    if(typeof(inputParent) !== "undefined" && inputParent !== null){
                        //console.log("inputParent : ", inputParent);
                        if(inputParent.hasOwnProperty("flickableDirection")){
                            //console.log("flickable inputparent : ", inputParent);
                            flickable = inputParent;
                            delayedLoading.start()
                            break;
                        }
                    }
                    inputParent = inputParent.parent;
                }while (typeof(inputParent) !== "undefined" && inputParent !== null);
            }
        }
    }

    function ensureVisible(flickable) {
        if (!Qt.inputMethod.visible || !inputItem || !flickable || !flickable.visible/* || !flickable.interactive*/)
            return;
        var verticallyFlickable = (flickable.flickableDirection === Flickable.HorizontalAndVerticalFlick || flickable.flickableDirection === Flickable.VerticalFlick
                                   || (flickable.flickableDirection === Flickable.AutoFlickDirection && flickable.contentHeight > flickable.height))

        if ((!verticallyFlickable) || !inputItem.hasOwnProperty("cursorRectangle"))
            return
        var cursorRectangle = flickable.contentItem.mapFromItem(inputItem, inputItem.cursorRectangle.x, inputItem.cursorRectangle.y)

        if (verticallyFlickable) {
            var scrollMarginVertical = verticalLimit ; //flickable.scrollMarginVertical ? flickable.scrollMarginVertical : 10
            /*console.log("scrollMarginVertical : ",scrollMarginVertical)
            console.log("cursorRectangle.y : ", cursorRectangle.y);
            console.log("inputItem.cursorRectangle.height : ", inputItem.cursorRectangle.height);
            console.log("inputItem.cursorRectangle.x : ", inputItem.cursorRectangle.x);
            console.log("inputItem.cursorRectangle.y : ", inputItem.cursorRectangle.y);
            console.log("flickable.height : ",flickable.height);
            console.log("flickable.contHeight : ",flickable.contentHeight);
            console.log("flickable.contentY before : ",flickable.contentY);
            console.log("flickable.y : ",flickable.y);
            console.log("appWindow.height",appWindow.height);*/

            if (((cursorRectangle.y + inputItem.cursorRectangle.height + flickable.y) - flickable.contentY) >= (appWindow.height - scrollMarginVertical)) {
                //console.log("*****MOVE UP TO DO*****");
                // The flickable is foo far down; move it up.
                //console.log("((cursorRectangle.y + inputItem.cursorRectangle.height + flickable.y) - flickable.contentY) - (appWindow.height - scrollMarginVertical)) : ",((cursorRectangle.y + inputItem.cursorRectangle.height + flickable.y) - flickable.contentY) - (appWindow.height - scrollMarginVertical));
                flickable.contentY = Math.round(flickable.contentY + ((cursorRectangle.y + inputItem.cursorRectangle.height + flickable.y) - flickable.contentY) - (appWindow.height - scrollMarginVertical)); //+ inputItem.cursorRectangle.height);
            }
            //console.log("flickable.contentY after : ",flickable.contentY);
        }
    }

    Timer {
        id: delayedLoading
        repeat: false
        interval: 25
        triggeredOnStart: false
        onTriggered: ensureVisible(flickable)
    }

    Connections {
        ignoreUnknownSignals: true
        target: Qt.inputMethod
        function onAnimatingChanged() { if (inputItem && !Qt.inputMethod.animating) delayedLoading.restart() }
        function onKeyboardRectangleChanged() { if (inputItem) delayedLoading.restart() }
        function onCursorRectangleChanged() { if (inputItem && inputItem.activeFocus) delayedLoading.restart() }
    }
}

