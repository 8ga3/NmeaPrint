/****************************************************************************
**
** Copyright (C) 2020 8ga3
** Contact: https://github.com/8ga3
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
****************************************************************************/
import QtQuick 2.0
import QtQuick.Window 2.12
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.2
import QtLocation 5.6
import QtPositioning 5.5
import "componets"
import "nmea.js" as Gnss

ApplicationWindow {
    id: window
    visible: true
    width: 800
    height: 680
    title: qsTr("NMEA Viewer")

    Component.onCompleted:{
        init()
    }

    function init() {
        comupdate()
        baudrateupdate()
    }
    
    function comupdate() {
        comboBoxPortNames.model.clear()
        
        var device = serialPort.comlist()
        for(var key in device){
            comboBoxPortNames.model.append({text:device[key]})
        }
        comboBoxPortNames.currentIndex = 0
    }
    
    function baudrateupdate() {
        comboBoxBaudrate.model.clear()
        
        var rate = serialPort.baudratelist()
        for(var key in rate){
            comboBoxBaudrate.model.append({text:rate[key]})
            if (rate[key] === 115200) {
                comboBoxBaudrate.currentIndex = key
            }
        }
    }
    
    function startstop() {
        if (button.text === "START") {
            serialPort.startSlot(comboBoxPortNames.currentText, comboBoxBaudrate.currentValue)
            button.text = "STOP"
        }
        else {
            serialPort.stopSlot()
            button.text = "START"
        }
    }

    GnssMap {
        id: map
        anchors.fill: parent
        plugin: mapPlugin
        focus: true
    }

    Plugin {
        id: mapPlugin
        name: "osm" // "mapboxgl", "esri", ...
        // specify plugin parameters if necessary
        // PluginParameter {
        //     name:
        //     value:
        // }
    }

    Rectangle {
        id: rectDevice
        width: 360
        height: 61
        color: "#80ffffff"
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        anchors.left: parent.left
        anchors.leftMargin: 4

        GridLayout {
            id: gridLayoutControl
            anchors.fill: parent
            anchors.margins: 4
            rowSpacing: 5
            columns: 3

            Text {
                id: element1
                text: qsTr("Serial Port:")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                font.pixelSize: 12
            }

            ComboBox {
                id: comboBoxPortNames
                width: 140
                height: 20
                Layout.minimumWidth: 80
                Layout.minimumHeight: 24
                Layout.preferredHeight: 24
                font.pointSize: 12
                Layout.fillWidth: true
                model: ListModel {
                    id: comportModel
                }
            }

            Button {
                id: button
                height: 20
                text: qsTr("START")
                Layout.minimumWidth: 80
                Layout.rowSpan: 2
                Layout.minimumHeight: 24
                Layout.preferredHeight: 24
                font.pointSize: 12
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.columnSpan: 1
                onClicked: startstop()
            }

            Text {
                id: element2
                text: qsTr("Baudrate:")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                font.pixelSize: 12
            }

            ComboBox {
                id: comboBoxBaudrate
                width: 140
                height: 20
                Layout.minimumWidth: 80
                Layout.minimumHeight: 24
                Layout.preferredHeight: 24
                font.pointSize: 12
                Layout.fillWidth: true
                model: ListModel {
                    id: baudrateModel
                }
            }
        }
    }

    Connections
    {
        target:serialPort

        function onRequest(text) {
            //console.log("received request:")

            let nmea = new Gnss.NMEA(text)

            viewBasicParam.updateParam(nmea)

            if (nmea.lat_ns !== "") {
                let lat = nmea.lat_ns === "N" ? nmea.lat : -nmea.lat
                let lon = nmea.lon_ew === "E" ? nmea.lon : -nmea.lon
                map.dispPos(lat, lon)
            }
            else {
                map.hiddenPos()
            }

            satellitesMap.updateSatellites(nmea.satellites, nmea.gsa)
            signalStrength.updateBarGraph(nmea.satellites, nmea.gsa)

            textNmea.text = text;
        }

        function onError(text) {
            console.log("received error:" + text)
            textNmea.text = text;
        }

        function onTimeout(text) {
            console.log("received timeout:" + text)
            textNmea.text = text;
        }
    }

    SatellitesMap {
        id: satellitesMap
        width: 300
        height: 300
        radius: width / 2
        color: "#80ffffff"
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.top: parent.top
        anchors.topMargin: 4
        lineColor: "#888888"
        textColor: "#888888"
    }

    Rectangle {
        id: rectBasicParam
        width: 180
        height: 280
        color: "#80ffffff"
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.top: satellitesMap.bottom
        anchors.topMargin: 4

        ViewBasicParam {
            id: viewBasicParam
            anchors.fill: parent
        }
    }

    Rectangle {
        id: rectBar
        height: 160
        color: "#80ffffff"
        anchors.right: satellitesMap.left
        anchors.rightMargin: 4
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.leftMargin: 4

        SignalStrength {
            id: signalStrength
            anchors.fill: parent
            anchors.margins: 4
            barMargin: 4
        }
    }

    Rectangle {
        id: rectNmea
        height: 250
        color: "#00ffffff"
        anchors.right: satellitesMap.left
        anchors.rightMargin: 4
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.top: rectBar.bottom
        anchors.topMargin: 4

        Text {
            id: textNmea
            text: qsTr("")
            clip: true
            anchors.fill: parent
            font.pixelSize: 12
        }
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:800;width:680}
}
##^##*/
