// pixL Pegasus Frontend

//Created by BozoTheGeek from AutoScroll.qml to do one for horizontal case.

import QtQuick 2.12

/// This item provides an infinitely looping, autoscrolling view into
/// a taller content.
/// You can change the scrolling speed (pixels per second), and the
/// additional delay before and after the the animation.
/// If the content fits into the view, no scrolling happens.

Flickable {
    id: container

    property int scrollWaitDuration: 1500
    property int pixelsPerSecond: 10
    property bool activated: true

    function stopScroll() {
        scrollAnimGroup.complete();
    }
    function restartScroll() {
        if(container.activated) scrollAnimGroup.restart();
    }

    clip: true
    flickableDirection: Flickable.HorizontalFlick
    contentWidth: contentItem.childrenRect.width
    contentHeight: height

    property int targetX: Math.max(contentWidth - width, 0);

    function recalcAnimation() {
        scrollAnimGroup.stop();
        contentX = 0;

        // the parameters of the sub-animations can't be properly
        // changed by regular binding while the group is running
        animScrollRight.to = targetX;
        animScrollRight.duration = (targetX / pixelsPerSecond) * 1000;
        animPauseHead.duration = scrollWaitDuration;
        animPauseTail.duration = scrollWaitDuration;

        if(container.activated) scrollAnimGroup.restart();
    }
    onTargetXChanged: recalcAnimation()
    onScrollWaitDurationChanged: recalcAnimation()
    onPixelsPerSecondChanged: recalcAnimation()

    // cancel the animation on user interaction
    onMovementStarted: scrollAnimGroup.stop()

    SequentialAnimation {
        id: scrollAnimGroup
        running: container.activated
        loops: Animation.Infinite

        PauseAnimation {
            id: animPauseHead
            duration: 0
        }
        NumberAnimation {
            id: animScrollRight
            target: container; property: "contentX"
            from: 0; to: 0; duration: 0
        }
        PauseAnimation {
            id: animPauseTail
            duration: 0
        }
        NumberAnimation {
            target: container; property: "contentX"
            to: 0; duration: 1000
        }
    }
}
