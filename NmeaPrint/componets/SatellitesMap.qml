

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


/**
  * @file SatellitesMap.qml
  * @brief GNSS衛星の天空における方位角と仰角をグラフ表示
  * @author Masaru Ebata
  * @date 2020/08/18
  * @details nmea.jsでパースしたNMEAフォーマット・データから、GNSS衛星の天空における方位角と仰角をグラフ表示します。
  */
import QtQuick 2.0
import QtQuick.Shapes 1.0
import QtTest 1.13

Rectangle {
    id: root
    color: "White"

    property color lineColor: "Black"
    property color textColor: "Black"
    property real rate: 0.9
    property real r: Math.min(width, height) / 2 * rate
    property real charHeight: Math.min(width, height) / 2 * (1 - rate)

    Repeater {
        model: [0, 45, 90, 135]

        Shape {
            width: 2
            height: root.r * 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            antialiasing: true
            rotation: modelData

            ShapePath {
                fillColor: "transparent" // stroke only
                strokeColor: root.lineColor
                strokeWidth: 1
                startX: width / 2
                startY: 0
                PathLine {
                    relativeX: 0
                    relativeY: height
                }
            }
        }
    }

    Repeater {
        model: [0, 30, 60]

        Shape {
            width: root.r * 2
            height: root.r * 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            antialiasing: true

            property real r: root.r * ((90 - modelData) / 90)

            ShapePath {
                fillColor: "transparent" // stroke only
                strokeColor: root.lineColor
                strokeWidth: 1

                startX: width / 2
                startY: height / 2 - r
                PathArc {
                    x: width / 2
                    y: height / 2 + r
                    radiusX: r
                    radiusY: r
                    useLargeArc: false
                }
                PathArc {
                    x: width / 2
                    y: height / 2 - r
                    radiusX: r
                    radiusY: r
                    useLargeArc: false
                }
            }
        }
    }

    Repeater {
        model: [0, 30, 60]

        Text {
            width: root.charHeight
            height: root.charHeight
            text: modelData
            verticalAlignment: Text.AlignTop
            horizontalAlignment: Text.AlignLeft
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -(root.r * ((90 - modelData) / 90))
                                          + root.charHeight / 2 + 4
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: root.charHeight / 2 + 4
            color: root.textColor
            font.pixelSize: root.charHeight - 4
        }
    }

    Repeater {
        model: [["N", 0], ["NE", 45], ["E", 90], ["SE", 135], ["S", 180], ["SW", 225], ["W", 270], ["NW", 315]]

        Text {
            width: root.charHeight
            height: (root.charHeight + root.r)
            text: modelData[0]
            rotation: modelData[1]
            transformOrigin: Item.Bottom
            verticalAlignment: Text.AlignTop
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -(height / 2)
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.textColor
            font.pixelSize: root.charHeight - 2
        }
    }

    Component {
        id: satItem

        Rectangle {
            width: modelData.size
            height: modelData.size
            radius: width / 2
            color: modelData.fillColor
            border.color: modelData.strokeColor
            border.width: 1
            z: modelData.z

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: elev * Math.sin(
                                                Math.PI * azimuth / 180)
            anchors.verticalCenterOffset: elev * -Math.cos(
                                              Math.PI * azimuth / 180)

            // 方位角（左手系北基準）
            // N: 0, 360
            // E: 90
            // S: 180
            // W: 270
            property real azimuth: modelData.azimuth
            // 極角（仰角）
            property real elev: root.r * (90 - modelData.elev) / 90

            Text {
                text: modelData.satNo
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                anchors.fill: parent
                color: modelData.textColor
                font.pixelSize: height / 2 - 2
            }
        }
    }

    Repeater {
        id: satItems
        anchors.fill: parent
        delegate: satItem
        //        model: root.itemElements
    }

    //    property var itemElements: [
    //        {
    //            "satNo": "000",
    //            "azimuth": 30,
    //            "elev": 80,
    //            "z": 1,
    //            "size": 24,
    //            "fillColor": "#c0ffffff",
    //            "strokeColor": "Black",
    //            "textColor": "Black"
    //        }
    //    ]
    function updateSatellites(satellites, gsa) {

        function searchGsid(gsa, gsid) {
            for (let g in gsa) {
                if (parseInt(gsa[g].gsid) === parseInt(gsid)) {
                    return gsa[g]
                }
            }
            return null
        }

        function searchSvid(svidArray, svid) {
            for (let s in svidArray) {
                if (parseInt(svidArray[s]) === parseInt(svid)) {
                    return true
                }
            }
            return false
        }

        let arr = []

        for (let gsid in satellites) {
            let gsidSats = satellites[gsid]
            let active = searchGsid(gsa, gsid)

            if (!active) {
                continue
            }

            for (let n in gsidSats) {
                let sat = gsidSats[n]

                let param = {
                    "satNo": sat.svid,
                    "azimuth": sat.azimuth,
                    "elev": sat.elev,
                    "z": 1,
                    "size": 24,
                    "fillColor": "#c0ffffff",
                    "strokeColor": "Black",
                    "textColor": "Black"
                }

                if (searchSvid(active.svid, sat.svid)) {
                    param["z"] = 2
                    param["fillColor"] = "#c04040ff"
                    param["textColor"] = "White"
                }

                arr.push(param)
            }
        }

        satItems.model = arr
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}D{i:15;anchors_height:100;anchors_width:100}
}
##^##*/

