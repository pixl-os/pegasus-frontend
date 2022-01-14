import QtQuick 2.12
import QtQuick.VirtualKeyboard 2.15

Item {
    property var flickable;
    property var inputParent;
    property var verticalLimit;
    property var inputItem: InputContext.inputItem //InputContext.priv.inputItem

    onInputItemChanged: {
        if (inputItem !== null){
            if(inputItem.parent !== null){
                inputParent = inputItem.parent;
                do{
                    if(typeof(inputParent) !== "undefined" && inputParent !== null){
                        console.log("inputParent : ", inputParent);
                        if(inputParent.hasOwnProperty("flickableDirection")){
                            console.log("flickable inputparent : ", inputParent);
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
        console.log("test 1 OK");
        var verticallyFlickable = (flickable.flickableDirection === Flickable.HorizontalAndVerticalFlick || flickable.flickableDirection === Flickable.VerticalFlick
                                   || (flickable.flickableDirection === Flickable.AutoFlickDirection && flickable.contentHeight > flickable.height))
        var horizontallyFlickable = (flickable.flickableDirection === Flickable.HorizontalAndVerticalFlick || flickable.flickableDirection === Flickable.HorizontalFlick
                                     || (flickable.flickableDirection === Flickable.AutoFlickDirection && flickable.contentWidth > flickable.width))

        if ((!verticallyFlickable && !horizontallyFlickable) || !inputItem.hasOwnProperty("cursorRectangle"))
            return
        console.log("test 2 OK");
        var cursorRectangle = flickable.contentItem.mapFromItem(inputItem, inputItem.cursorRectangle.x, inputItem.cursorRectangle.y)

        if (verticallyFlickable) {
            console.log("test 3 OK");
            var scrollMarginVertical = verticalLimit ; //flickable.scrollMarginVertical ? flickable.scrollMarginVertical : 10
            console.log("scrollMarginVertical : ",scrollMarginVertical)
            console.log("cursorRectangle.y : ", cursorRectangle.y);
            console.log("flickable.height : ",flickable.height);
            console.log("flickable.contentY before : ",flickable.contentY);
            console.log("flickable.y before : ",flickable.y);
            console.log("appWindow.height",appWindow.height);

            if ((cursorRectangle.y - flickable.contentY) >= (appWindow.height - scrollMarginVertical - flickable.y)) {
                console.log("test 4 OK");
                // The flickable is foo far down; move it up.
                flickable.contentY = flickable.contentY + (cursorRectangle.y - (appWindow.height - scrollMarginVertical - flickable.y)); //+ inputItem.cursorRectangle.height);
            }
            /*} else if (flickable.contentY + flickable.height <= cursorRectangle.y  + inputItem.cursorRectangle.height + scrollMarginVertical) {
                console.log("test 5 OK");
                // The flickable is foo far up; move it down.
                flickable.contentY = Math.min(flickable.contentHeight - flickable.height, cursorRectangle.y + inputItem.cursorRectangle.height - flickable.height + scrollMarginVertical)
            }*/

            console.log("flickable.contentY after : ",flickable.contentY);

            /*if (flickable.contentY >= cursorRectangle.y - scrollMarginVertical) {
                console.log("test 4 OK");
                // The flickable is foo far down; move it up.
                flickable.contentY = Math.max(0, cursorRectangle.y  - scrollMarginVertical)
            } else if (flickable.contentY + flickable.height <= cursorRectangle.y  + inputItem.cursorRectangle.height + scrollMarginVertical) {
                console.log("test 5 OK");
                // The flickable is foo far up; move it down.
                flickable.contentY = Math.min(flickable.contentHeight - flickable.height, cursorRectangle.y + inputItem.cursorRectangle.height - flickable.height + scrollMarginVertical)
            }*/
        }
//        if (horizontallyFlickable) {
//            var scrollMarginHorizontal = flickable.scrollMarginHorizontal ? flickable.scrollMarginHorizontal : 10
//            if (flickable.contentX >= cursorRectangle.x - scrollMarginHorizontal) {
//                // The flickable is foo far down; move it up.
//                flickable.contentX = Math.max(0, cursorRectangle.x - scrollMarginHorizontal)
//            } else if (flickable.contentX + flickable.width <= cursorRectangle.x + inputItem.cursorRectangle.width + scrollMarginHorizontal) {
//                // The flickable is foo far up; move it down.
//                flickable.contentX = Math.min(flickable.contentWidth - flickable.width, cursorRectangle.x + inputItem.cursorRectangle.width - flickable.width + scrollMarginHorizontal)
//            }
//        }
    }
    Timer {
        id: delayedLoading
        repeat: false
        interval: 300
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


/*
    Connections {
        ignoreUnknownSignals: true
        target: Qt.inputMethod
        onKeyboardRectangleChanged: delayedLoading.start()
    }
    Connections {
        ignoreUnknownSignals: true
        target: inputItem
        enabled: inputItem && inputItem.activeFocus
        onCursorRectangleChanged: delayedLoading.start()
    }*/
}

