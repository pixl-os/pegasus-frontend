
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

# openGL renderer (graphic card name in major of cases)
glxinfo | grep "OpenGL renderer" | cut -d ':' -f 2 | cut -c 2-

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

# Network
ifconfig eth0 2> /dev/null | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'
ifconfig wlan0 2> /dev/null | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'

#new way to manage specific cases also:
ifconfig 2> /dev/null | grep -A1 '^e'| grep "inet addr:" | grep -v 127.0.0.1 | sed -e 's/Bcast//' | cut -d: -f2
ifconfig 2> /dev/null | grep -A1 '^w'| grep "inet addr:" | grep -v 127.0.0.1 | sed -e 's/Bcast//' | cut -d: -f2
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
        { name: qsTr("Linux Kernel :"), cmd: api.internal.system.run("echo $(uname -s) $(uname -r)") || "N/A" },
        { name: qsTr("Architecture :"), cmd: api.internal.system.run("uname -m") || "N/A" },
        { name: qsTr("CPU :"), cmd: api.internal.system.run("grep 'model name' /proc/cpuinfo | cut -d ':' -f 2 | cut -c 2- | uniq") || "N/A" },
        { name: qsTr("CPU Thread Number :"), cmd: api.internal.system.run("grep processor /proc/cpuinfo | wc -l | grep '\\S'") || "N/A" },
        { name: qsTr("CPU Maximum Frequency :"), cmd: api.internal.system.run("cpu_freq_max=$(cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq | uniq); echo $(($cpu_freq_max/1000000)).$((($cpu_freq_max/100000) % 10)) GHz") || "N/A" },
        { name: qsTr("RAM (free/total):"), cmd: api.internal.system.run("mem_total=$(free --mega -t | awk 'NR>3{total+=$2}END{print total}'); mem_free=$(free --mega -t | awk 'NR>3{free+=$4}END{print free}'); echo $mem_free/$mem_total MB") || "N/A" },
        { name: qsTr("GPU(s) :"), cmd: "\n" + api.internal.system.run("lspci | grep -i 'vga\\|3d\\|2d' | cut -d ':' -f 3 | grep '\\S'") || "N/A" },
        { name: qsTr("Video RAM :"), cmd: api.internal.system.run("grep -i 'video memory' /tmp/glxinfo.tmp | cut -d ':' -f 2") || "N/A" },
        { name: qsTr("OpenGL ES :"), cmd: api.internal.system.run("grep 'OpenGL ES profile version string' /tmp/glxinfo.tmp | cut -d ':' -f 2 | cut -c 2-") || "N/A" },
        { name: qsTr("OpenGL Core :"), cmd: api.internal.system.run("grep 'OpenGL core profile version string' /tmp/glxinfo.tmp | cut -d ':' -f 2 | cut -c 2-") || "N/A" },
        { name: qsTr("OpenGL Vendor/Driver :"), cmd: api.internal.system.run("grep 'OpenGL vendor string' /tmp/glxinfo.tmp | cut -d ':' -f 2 | cut -c 2-") || "N/A" },
        { name: qsTr("OpenGL Renderer :"), cmd: api.internal.system.run("grep 'OpenGL renderer' /tmp/glxinfo.tmp | cut -d ':' -f 2 | cut -c 2- | grep '\\S'") || "N/A" },
        { name: qsTr("Vulkan Renderer version :"), cmd: api.internal.system.run("grep 'Vulkan Instance Version:' /tmp/vulkaninfo.tmp | cut -d ':' -f 2") || "N/A" },
    ]

    property var model2: [
        //{ name: qsTr("System Disk Usage :"), cmd: api.internal.system.run("df -mT | awk \'NR>1 && ($7 == \'/\' || $7 == \'/dev\' || $7 == \'/boot\' || $7 == \'/tmp\' || $7 == \'/var\' || $7 == \'/overlay/lower\')\' | awk \'NF-=2\' | uniq | awk \'{total+=$3;used+=$4;free+=$5}END{if(total>1048576){total_out=total\/1048576;used_out=used\/1048576;unit_out=\'TB\';} else {total_out=total\/1024;used_out=used\/1024;unit_out=\'GB\'};percentage=used*100\/total;printf(\'%.2f\/%.2f %s (%.1f %)\n\',used_out,total_out,unit_out,percentage)}\'") },
        { name: qsTr("Wifi Local IP :"), cmd: api.internal.system.run("ifconfig 2> /dev/null | grep -A1 '^w'| grep 'inet addr:' | grep -v 127.0.0.1 | sed -e 's/Bcast//' | cut -d: -f2") || "N/A" },
        { name: qsTr("Ethernet Local IP :"), cmd: api.internal.system.run("ifconfig 2> /dev/null | grep -A1 '^e'| grep 'inet addr:' | grep -v 127.0.0.1 | sed -e 's/Bcast//' | cut -d: -f2") || "N/A" },
        { name: qsTr("External IP :"), cmd: api.internal.system.run("curl -4 'http://icanhazip.com/' 2> /dev/null") || "N/A" },
        { name: qsTr("CPU Temperature :"), cmd: api.internal.system.run("sensors -A '*-isa-*' | cut -d '(' -f 1 | sed -e 's/C  /C/g'") || "N/A" },
        { name: qsTr("Number of system(s) :"), cmd: api.collections.count || "N/A" },
        { name: qsTr("Number of game(s) :"), cmd: api.allGames.count || "N/A" },
        //{ name: qsTr("GPU Temperature :"), cmd: api.internal.system.run("gpu_temp=$(vcgencmd measure_temp | cut -d '=' -f 2 | cut -d \' -f 1); echo '$gpu_temp'$'\xc2\xb0'C")},
        //New Method using generique way for buildroot and multi-indexes
        //{ name: qsTr("All System Temperature(s) :"), cmd: "\n"
        //+ api.internal.system.run("(((paste <(cat /sys/class/thermal/thermal_zone*/temp | sed 's/\\(.\\)..$/.\\1°C/' | tr -s [:space:]) <(cat /sys/class/thermal/thermal_zone*/type | tr -s [:space:])) | awk '{print $1 \" - \" $2}') && ((p=\"_input\";l=\"_label\";s=\"0 1 2 3 4 5 6 7\";t=\"0 1 2 3 4\"; for i in $s; do for j in $t; do paste <(cat /sys/class/hwmon/hwmon$i/temp$j$p | sed 's/\\(.\\)..$/.\\1°C/' | tr -s [:space:]) <(cat /sys/class/hwmon/hwmon$i/name | tr -s [:space:]) <(cat /sys/class/hwmon/hwmon$i/temp$j$l | tr -s [:space:]); echo \" \"; done; done )| grep -i \"°C\" | awk -F ' ' '$1 ~ /°C/  {print $1 \" - \" $2 \" \" $3 \" \" $4 \" \" $5}')) | grep -e ' - ' | sort -u -k1,5")},
        //+ api.internal.system.run("(((paste <(cat /sys/class/thermal/thermal_zone*/temp | sed 's/\\(.\\)..$/.\\1°C/' | tr -s [:space:]) <(cat /sys/class/thermal/thermal_zone*/type | tr -s [:space:])) | awk '{print $1 \" - \" $2}') && ((paste <(cat /sys/class/hwmon/hwmon*/temp*_input | sed 's/\\(.\\)..$/.\\1°C/' | tr -s [:space:]) <(cat /sys/class/hwmon/hwmon*/name | tr -s [:space:]) <(cat /sys/class/hwmon/hwmon*/temp*_label | tr -s [:space:])) | awk -F ' ' 'length($2)>0 {print $1 \" - \" $2 $3}')) | sort -u -k1,4")},
        //other methods but not working on all PCs
        //{ name: qsTr("                           "), cmd: api.internal.system.run("paste <(cat /sys/class/hwmon/hwmon*/name) <(cat /sys/class/hwmon/hwmon*/temp*_input) | sed 's/\\(.\\)..$/.\\1°C/'")},
        //{ name: qsTr("GPU Temperature(s) :"), cmd: api.internal.system.run("paste <(cat /sys/class/hwmon/hwmon*/device/graphics/fb*/device/hwmon/hwmon*/name) <(cat /sys/class/hwmon/hwmon*/device/graphics/fb*/device/hwmon/hwmon*/temp*_input) | sed 's/\\(.\\)..$/.\\1°C/'")},
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
            width: root.width * 0.9
            height: contentColumn.height
            Row{
                Column {
                    id: contentColumn
                    spacing: vpx(5)
                    width: ((content.width - spaceColumn.width) /3) * 2 // 2/3 of screen
                    height: implicitHeight
                    visible: true
                    Item {
                        width: parent.width
                        height: implicitHeight + vpx(30)
                    }
                    ListView {
                        width: contentColumn.width
                        height: vpx(520)
                        model: root.model
                        spacing: vpx(15)
                        focus: true
                        highlightMoveDuration : 0

                        move: Transition {
                            NumberAnimation { properties: "x,y"; duration: 1000 }
                        }
                        delegate: Rectangle {
                            width: contentColumn.width
                            height: (textresult.lineCount) > 1 ? (textresult.lineCount) * vpx(20) : vpx(20)
                            //need to do linecount-1 due to usual crlf at the end of each command result

                            color: "transparent"
                            // cross operability with ListModel and plain JS object list
                            property var item: model.modelData ? model.modelData : model

                            //always visible for the moment
                            //visible: textresult.lineCount-1 > 0 ? true : ((textresult.text != '0' && textresult.text != '') ? true : false)

                            Text {
                                id: title
                                padding: vpx(5)
                                font.pixelSize: vpx(15)
                                color: themeColor.textValue
                                anchors.left: parent.left
                                verticalAlignment: Text.AlignVCenter
                                text: item.name
                            }
                            Text {
                                id: textresult
                                padding: vpx(5)
                                font.pixelSize: vpx(15)
                                color: themeColor.textValue
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignRight
                                anchors.right: parent.right
                                anchors.left: item.cmd.startsWith("\n") ? parent.left : title.right
                                text: item.cmd.startsWith("\n") ? ("\n" + item.cmd.trim()) : item.cmd.trim()
                                elide: Text.ElideRight



                            }
                            Rectangle {
                                width: contentColumn.width
                                height: vpx(1)
                                color: "grey"
                                opacity: 0.1
                                radius: vpx(8)
                            }
                        }
                    }
                }
                Column {
                    id: spaceColumn
                    spacing: vpx(5)
                    width: root.width * 0.05
                    height: implicitHeight
                    visible: true
                    Item {
                        width: parent.width
                        height: implicitHeight + vpx(30)
                    }
                }

                Column {
                    id: contentColumn2
                    spacing: vpx(5)
                    width: ((content.width - spaceColumn.width) /3) * 1 // 1/3 of screen
                    height: implicitHeight
                    visible: true
                    Item {
                        width: parent.width
                        height: implicitHeight + vpx(30)
                    }
                    ListView {
                        width: contentColumn2.width
                        height: vpx(520)
                        model: root.model2
                        spacing: vpx(15)
                        focus: true
                        highlightMoveDuration : 0

                        move: Transition {
                            NumberAnimation { properties: "x,y"; duration: 1000 }
                        }
                        delegate: Rectangle {
                            width: contentColumn2.width
                            height: (textresult2.lineCount) > 1 ? (textresult2.lineCount-1) * vpx(20) : vpx(20)
                            //need to do linecount-1 due to usual crlf at the end of each command result

                            color: "transparent"
                            // cross operability with ListModel and plain JS object list
                            property var item: model.modelData ? model.modelData : model

                            //always visible for the moment
                            //visible: textresult.lineCount-1 > 0 ? true : ((textresult.text != '0' && textresult.text != '') ? true : false)

                            Text {
                                padding: vpx(5)
                                font.pixelSize: vpx(15)
                                color: themeColor.textValue
                                anchors.left: parent.left
                                verticalAlignment: Text.AlignVCenter
                                text: item.name
                            }
                            Text {
                                id: textresult2
                                padding: vpx(5)
                                font.pixelSize: vpx(15)
                                color: themeColor.textValue
                                verticalAlignment: Text.AlignVCenter
                                anchors.right: parent.right
                                text: item.cmd
                            }
                            Rectangle {
                                width: contentColumn.width
                                height: vpx(1)
                                color: "grey"
                                opacity: 0.1
                                radius: vpx(8)
                            }
                        }
                    }
                }
            }
        }
    }
}
