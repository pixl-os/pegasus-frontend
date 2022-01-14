
import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Window 2.12

/*
#### Raspberry Pi 4 Commands :
# User Disk Usage - Used Size :
df -mT | awk 'NR>1 && $7 == "\/recalbox\/share"' | awk 'NF-=2' | uniq | awk '{total+=$3;used+=$4;free+=$5}END{if(total>1048576){total_out=total/1048576;used_out=used/1048576;unit_out="TB";} else {total_out=total/1024;used_out=used/1024;unit_out="GB"};percentage=used*100/total;printf("%.2f/%.2f %s (%.1f \%)\n",used_out,total_out,unit_out,percentage)}'

# System Disk Usage :
df -mT | awk 'NR>1 && ($7 == "/" || $7 == "/dev" || $7 == "/boot" || $7 == "/tmp" || $7 == "/var" || $7 == "/overlay/lower")' | awk 'NF-=2' | uniq | awk '{total+=$3;used+=$4;free+=$5}END{if(total>1048576){total_out=total/1048576;used_out=used/1048576;unit_out="TB";} else {total_out=total/1024;used_out=used/1024;unit_out="GB"};percentage=used*100/total;printf("%.2f/%.2f %s (%.1f %)\n",used_out,total_out,unit_out,percentage)}'

# CPU Temperature :
cpu_temp=$(</sys/class/thermal/thermal_zone0/temp); echo "$(($cpu_temp/1000))"."$((($cpu_temp/100) % ($cpu_temp/1000)))"$'\xc2\xb0'C

# GPU Temperature :
gpu_temp=$(vcgencmd measure_temp | cut -d '=' -f 2 | cut -d \' -f 1); echo "$gpu_temp"$'\xc2\xb0'C

# Architecture - Option 1 :
arch

# Architecture - Option 2 :
uname -m

# System :
echo $(uname -s) $(uname -r)

# Available Memory :
mem_total=$(free --mega -t | awk 'NR>3{total+=$2}END{print total}'); mem_free=$(free --mega -t | awk 'NR>3{free+=$4}END{print free}'); echo $mem_free/$mem_total MB

# OpenGL Core Version :
# mesa-utils required !
# sudo apt install -y mesa-utils
# glxinfo | grep "OpenGL ES profile version string" | cut -d ':' -f 2 | cut -c 2-
# glxinfo | grep "OpenGL core profile version string" | cut -d ':' -f 2 | cut -c 2-

# Vulkan Version :
# Install vulkan-tools ??
# vulkaninfo

# CPU Model :
cat /proc/cpuinfo | grep "model name" | cut -d ':' -f 2 | cut -c 2- | uniq

# CPU Number :
grep processor /proc/cpuinfo | wc -l

# CPU Max Frequency :*/
// cpu_freq_max=$(cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq | uniq); echo $(($cpu_freq_max/1000000)).$((($cpu_freq_max/100000) % 10)) GHz
/*

# CPU Feature :
# Kékécé ???

# Video Driver :
# Graphics API :


# Vendor :
# lshw required
# sudo apt install -y lshw
sudo lshw -c display | grep vendor | cut -d ':' -f 2 | cut -c 2-

# Renderer :
# lshw required
# sudo apt install -y lshw
sudo lshw -c display | grep product | cut -d ':' -f 2 | cut -c 2-

# Version :


#temp intel/amd cpu:
cat /sys/class/thermal/thermal_zone0/temp 2> /dev/null || cat /sys/class/hwmon/hwmon0/temp1_input 2> /dev/null || echo 0

*/
FocusScope {
    id: root

    signal close
    signal openVideoSettings

    width: parent.width
    height: parent.height
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.close();
            api.internal.recalbox.saveParameters();
        }
    }

    // define plain JS object list
    property var model: [
        {name: qsTr("Linux Kernel :"), cmd: api.internal.system.run("echo $(uname -s) $(uname -r)")},
        {name: qsTr("Architecture :"), cmd: api.internal.system.run("uname -m")},
        {name: qsTr("CPU :"), cmd: api.internal.system.run("cat /proc/cpuinfo | grep 'model name' | cut -d ':' -f 2 | cut -c 2- | uniq")},
        {name: qsTr("CPU Number(s) :"),cmd: api.internal.system.run("grep processor /proc/cpuinfo | wc -l")},
        {name: qsTr("CPU Maximum frequency :"), cmd: api.internal.system.run("cpu_freq_max=$(cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq | uniq); echo $(($cpu_freq_max/1000000)).$((($cpu_freq_max/100000) % 10)) GHz")},
        {name: qsTr("CPU Temperature :"), cmd: api.internal.system.run("cat /sys/class/thermal/thermal_zone0/temp 2> /dev/null || cat /sys/class/hwmon/hwmon0/temp1_input 2> /dev/null || echo 0")},
        {name: qsTr("RAM :"), cmd: api.internal.system.run("mem_total=$(free --mega -t | awk 'NR>3{total+=$2}END{print total}'); mem_free=$(free --mega -t | awk 'NR>3{free+=$4}END{print free}'); echo $mem_free/$mem_total MB")},
        {name: qsTr("OpenGL :"), cmd: api.internal.system.run("glxinfo | grep 'OpenGL ES profile version string' | cut -d ':' -f 2 | cut -c 2-")},
        {name: qsTr("Local IP :"), cmd: api.internal.system.run("ifconfig wlan0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'")},
        {name: qsTr("External IP :"), cmd: api.internal.system.run("curl -4 'http://icanhazip.com/'")},
        {name: qsTr("Renderer :"), cmd: api.internal.system.run("lshw -c display | grep product | cut -d ':' -f 2 | cut -c 2-")},
        {name: qsTr("Vendor :"), cmd: api.internal.system.run("lshw -c display | grep vendor | cut -d ':' -f 2 | cut -c 2-")}
    ]

    PegasusUtils.HorizontalSwipeArea {
        anchors.fill: parent
        onSwipeRight: root.close()
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: root.close()
    }
    ScreenHeader {
        id: header
        text: qsTr("Settings > System Information") + api.tr
        z: 2
    }
    Flickable {
        id: container

        width: content.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: header.bottom
        anchors.bottom: parent.bottom

        contentWidth: content.width
        contentHeight: content.height

        Behavior on contentY { PropertyAnimation { duration: 100 } }
        boundsBehavior: Flickable.StopAtBounds
        boundsMovement: Flickable.StopAtBounds

        readonly property int yBreakpoint: height * 0.7
        readonly property int maxContentY: contentHeight - height

        function onFocus(Column) {
            if (Column.focus)
                contentY = Math.min(Math.max(0, Column.y - yBreakpoint), maxContentY);
        }
        FocusScope {
            id: content
            focus: true
            enabled: focus
            width: contentColumn.width
            height: contentColumn.height

            Column {
                id: contentColumn
                spacing: vpx(5)
                width: root.width * 0.7
                height: implicitHeight

                Item {
                    width: parent.width
                    height: implicitHeight + vpx(30)
                }
                ListView {
                    width: contentColumn.width
                    height: vpx(480)
                    model: root.model
                    spacing: vpx(15)
                    populate: Transition {
                             NumberAnimation { properties: "x,y"; duration: 100 }
                                             }
                    delegate: Rectangle {
                        width: contentColumn.width
                        height: vpx(20)
                        color: "transparent"
                        // cross operability with ListModel and plain JS object list
                        property var item: model.modelData ? model.modelData : model

                        Text {
                            padding: vpx(10)
                            font.pixelSize: vpx(15)
                            color: themeColor.textValue
                            anchors.left: parent.left
                            verticalAlignment: Text.AlignVCenter
                            text: item.name
                        }
                        Text {
                            padding: vpx(10)
                            font.pixelSize: vpx(15)
                            color: themeColor.textValue
                            anchors.right: parent.right
                            verticalAlignment: Text.AlignVCenter
                            text: item.cmd
                        }
                        Rectangle {
                            width: contentColumn.width
                            height: vpx(1)
                            color: "grey"
                            opacity: 0.2
                            radius: vpx(8)
                        }
                    }
                }
            }
        }
    }
}
