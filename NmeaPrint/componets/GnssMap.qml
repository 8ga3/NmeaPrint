
/****************************************************************************
**
** Copyright (C) 2020 8ga3
** Contact: https://github.com/8ga3
**
** Including the part of the MapComponent.qml
** It is part of the examples of the Qt Toolkit.
** https://www.qt.io/licensing/
** Copyright (C) 2017 The Qt Company Ltd.
** Released under the BSD Licenses.
**
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
import QtQuick.Controls 2.4
import QtLocation 5.6
import QtPositioning 5.5

Map {
    id: map
    center: QtPositioning.coordinate(35.6812362, 139.7649361) // Tokyo Station
    zoomLevel: 16

    // Enable pan, flick, and pinch gestures to zoom in and out
    gesture.acceptedGestures: MapGestureArea.PanGesture | MapGestureArea.FlickGesture
                              | MapGestureArea.PinchGesture | MapGestureArea.RotationGesture
    // gesture.acceptedGestures: MapGestureArea.PanGesture | MapGestureArea.FlickGesture | MapGestureArea.PinchGesture | MapGestureArea.RotationGesture | MapGestureArea.TiltGesture
    gesture.flickDeceleration: 3000
    gesture.enabled: true

    copyrightsVisible: true
    onCopyrightLinkActivated: Qt.openUrlExternally(link)

    property int lastX: -1
    property int lastY: -1
    property int pressX: -1
    property int pressY: -1
    property int jitterThreshold: 30
    property bool followme: true
    property variant scaleLengths: [5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000, 500000, 1000000, 2000000]

    onCenterChanged: {
        scaleTimer.restart()
        if (map.followme && deviceLocate.opacity > 0) {
            if (map.center !== deviceLocate.coordinate) {
                map.followme = false
                checkBox.checked = false
            }
        }
    }

    onZoomLevelChanged: {
        scaleTimer.restart()
        if (map.followme)
            map.center = deviceLocate.coordinate
    }

    onWidthChanged: {
        scaleTimer.restart()
    }

    onHeightChanged: {
        scaleTimer.restart()
    }

    // 取得した経緯度を表示
    function dispPos(lat, lon) {
        let coordinate = QtPositioning.coordinate(lat, lon)
        deviceLocate.coordinate = coordinate
        if (map.followme)
            map.center = coordinate
        deviceLocate.opacity = 0.5
    }

    // 取得経緯度を非表示
    function hiddenPos() {
        deviceLocate.opacity = 0
    }

    function calculateScale() {
        let coord1, coord2, dist, text, f
        f = 0
        coord1 = map.toCoordinate(Qt.point(0, ruler.y))
        coord2 = map.toCoordinate(Qt.point(0 + scaleImage.sourceSize.width,
                                           ruler.y))
        dist = Math.round(coord1.distanceTo(coord2))

        if (dist === 0) {

            // not visible
        } else {
            for (var i = 0; i < scaleLengths.length - 1; i++) {
                if (dist < (scaleLengths[i] + scaleLengths[i + 1]) / 2) {
                    f = scaleLengths[i] / dist
                    dist = scaleLengths[i]
                    break
                }
            }
            if (f === 0) {
                f = dist / scaleLengths[i]
                dist = scaleLengths[i]
            }
        }

        text = formatDistance(dist)
        scaleImage.width = (scaleImage.sourceSize.width * f) - 2 * scaleImageLeft.sourceSize.width
        scaleText.text = text
    }

    function formatDistance(meters) {
        let dist = Math.round(meters)
        if (dist > 1000) {
            if (dist > 100000) {
                dist = Math.round(dist / 1000)
            } else {
                dist = Math.round(dist / 100)
                dist = dist / 10
            }
            dist = dist + " km"
        } else {
            dist = dist + " m"
        }
        return dist
    }

    MapQuickItem {
        id: deviceLocate
        sourceItem: Rectangle {
            width: 14
            height: 14
            color: "#e41e25"
            border.width: 2
            border.color: "white"
            smooth: true
            radius: 7
        }
        coordinate: map.center
        opacity: 0
        anchorPoint: Qt.point(sourceItem.width / 2, sourceItem.height / 2)
    }

    Item {
        id: ruler
        z: map.z + 3
        visible: scaleText.text !== "0 m"
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 20
        height: scaleText.height * 2
        width: scaleImage.width

        Image {
            id: scaleImageLeft
            source: "../resources/scale_end.png"
            anchors.bottom: parent.bottom
            anchors.right: scaleImage.left
        }
        Image {
            id: scaleImage
            source: "../resources/scale.png"
            anchors.bottom: parent.bottom
            anchors.right: scaleImageRight.left
        }
        Image {
            id: scaleImageRight
            source: "../resources/scale_end.png"
            anchors.bottom: parent.bottom
            anchors.right: parent.right
        }
        Label {
            id: scaleText
            color: "#004EAE"
            anchors.centerIn: parent
            text: "0 m"
        }
        Component.onCompleted: {
            map.calculateScale()
        }
    }

    CheckBox {
        id: checkBox
        width: 28
        z: map.z + 3
        text: qsTr("")
        spacing: 0
        opacity: 0.5
        padding: 0
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48
        checked: true
        onClicked: map.followme = checked
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_Plus) {
            map.zoomLevel++
        } else if (event.key === Qt.Key_Minus) {
            map.zoomLevel--
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right
                   || event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
            var dx = 0
            var dy = 0

            switch (event.key) {
            case Qt.Key_Left:
                dx = map.width / 4
                break
            case Qt.Key_Right:
                dx = -map.width / 4
                break
            case Qt.Key_Up:
                dy = map.height / 4
                break
            case Qt.Key_Down:
                dy = -map.height / 4
                break
            }

            var mapCenterPoint = Qt.point(map.width / 2.0 - dx,
                                          map.height / 2.0 - dy)
            map.center = map.toCoordinate(mapCenterPoint)
        }
    }

    Timer {
        id: scaleTimer
        interval: 100
        running: false
        repeat: false
        onTriggered: {
            map.calculateScale()
        }
    }

    MouseArea {
        id: mouseArea
        property variant lastCoordinate
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPressed: {
            map.lastX = mouse.x
            map.lastY = mouse.y
            map.pressX = mouse.x
            map.pressY = mouse.y
            lastCoordinate = map.toCoordinate(Qt.point(mouse.x, mouse.y))
        }

        onPositionChanged: {
            if (mouse.button == Qt.LeftButton) {
                map.lastX = mouse.x
                map.lastY = mouse.y
            }
        }

        onDoubleClicked: {
            var mouseGeoPos = map.toCoordinate(Qt.point(mouse.x, mouse.y))
            var preZoomPoint = map.fromCoordinate(mouseGeoPos, false)
            if (mouse.button === Qt.LeftButton) {
                map.zoomLevel = Math.floor(map.zoomLevel + 1)
            } else if (mouse.button === Qt.RightButton) {
                map.zoomLevel = Math.floor(map.zoomLevel - 1)
            }
            var postZoomPoint = map.fromCoordinate(mouseGeoPos, false)
            var dx = postZoomPoint.x - preZoomPoint.x
            var dy = postZoomPoint.y - preZoomPoint.y

            var mapCenterPoint = Qt.point(map.width / 2.0 + dx,
                                          map.height / 2.0 + dy)
            map.center = map.toCoordinate(mapCenterPoint)

            lastX = -1
            lastY = -1
        }

        onPressAndHold: {
            if (Math.abs(map.pressX - mouse.x) < map.jitterThreshold
                    && Math.abs(map.pressY - mouse.y) < map.jitterThreshold) {
                showMainMenu(lastCoordinate)
            }
        }
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/

