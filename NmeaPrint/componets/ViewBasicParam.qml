

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
  * @file ViewBasicParam.qml
  * @brief GNSS受信モジュールのステータス表示
  * @author Masaru Ebata
  * @date 2020/08/18
  * @details nmea.jsでパースしたNMEAフォーマット・データから、GNSS受信ステータスをテーブル表示します。
  */
import QtQuick 2.0
import QtQuick.Layouts 1.2

Item {
    function updateParam(nmea) {
        elementDate.text = nmea.year + "/" + nmea.month + "/" + nmea.day
        elementTime.text = ("00" + nmea.hour).slice(
                    -2) + ":" + ("00" + nmea.minite).slice(
                    -2) + ":" + ("00" + nmea.secound).slice(
                    -2) + "." + (nmea.millisecond + "00").slice(0, 3)
        elementLat.text = nmea.lat_ns + " " + nmea.lat.toFixed(6)
        elementLon.text = nmea.lon_ew + " " + nmea.lon.toFixed(6)
        elementAlt.text = nmea.altitude
        elementQuality.text = nmea.qualityDesc()
        elementSat.text = nmea.satellites_num
        elementHdop.text = nmea.hdop
        elementSpeed.text = nmea.speed + " km/h"
        elementTrackTrue.text = nmea.trackTrue
        elementTrackMag.text = nmea.trackMag
        elementMagVar.text = nmea.varDir + " " + nmea.magVar
    }

    GridLayout {
        layoutDirection: Qt.LeftToRight
        flow: GridLayout.LeftToRight
        columnSpacing: 10
        rowSpacing: 5
        rows: 5
        columns: 2
        anchors.fill: parent

        Text {
            id: elementDateTitle
            text: qsTr("Date")
            Layout.minimumWidth: 80
            Layout.maximumWidth: 80
            Layout.minimumHeight: 15
            Layout.maximumHeight: 15
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 12
        }

        Text {
            id: elementDate
            text: qsTr("No data")
            Layout.fillWidth: true
            Layout.maximumHeight: 15
            Layout.minimumHeight: 15
            font.pixelSize: 12
        }

        Text {
            id: elementTimeTitle
            text: qsTr("Time")
            Layout.maximumWidth: 80
            Layout.minimumWidth: 80
            Layout.maximumHeight: 15
            Layout.minimumHeight: 15
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 12
        }

        Text {
            id: elementTime
            text: qsTr("No data")
            Layout.maximumHeight: 15
            Layout.minimumHeight: 15
            Layout.fillWidth: true
            font.pixelSize: 12
        }

        Text {
            id: elementLatTitle
            text: qsTr("Latitude")
            Layout.maximumWidth: 80
            Layout.minimumWidth: 80
            Layout.maximumHeight: 15
            Layout.minimumHeight: 15
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 12
        }

        Text {
            id: elementLat
            text: qsTr("No data")
            Layout.minimumHeight: 15
            Layout.maximumHeight: 15
            Layout.fillWidth: true
            font.pixelSize: 12
        }

        Text {
            id: elementLonTitle
            text: qsTr("Longitude")
            Layout.minimumWidth: 80
            Layout.maximumWidth: 80
            Layout.maximumHeight: 15
            Layout.minimumHeight: 15
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
        }

        Text {
            id: elementLon
            text: qsTr("No data")
            Layout.maximumHeight: 15
            Layout.minimumHeight: 15
            font.pixelSize: 12
            Layout.fillWidth: true
        }

        Text {
            id: elementAltTitle
            text: qsTr("Altitude")
            Layout.minimumWidth: 80
            Layout.maximumWidth: 80
            Layout.maximumHeight: 15
            Layout.minimumHeight: 15
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
        }

        Text {
            id: elementAlt
            text: qsTr("No data")
            Layout.maximumHeight: 15
            Layout.minimumHeight: 15
            font.pixelSize: 12
            Layout.fillWidth: true
        }

        Text {
            id: elementQualityTitle
            text: qsTr("Quality")
            Layout.minimumWidth: 80
            Layout.maximumWidth: 80
            Layout.maximumHeight: 15
            Layout.minimumHeight: 15
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
        }

        Text {
            id: elementQuality
            text: qsTr("No data")
            Layout.maximumHeight: 15
            Layout.minimumHeight: 15
            font.pixelSize: 12
            Layout.fillWidth: true
        }

        Text {
            id: elementSatTitle
            text: qsTr("Satellite")
            Layout.minimumWidth: 80
            Layout.maximumWidth: 80
            Layout.maximumHeight: 15
            Layout.minimumHeight: 15
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
        }

        Text {
            id: elementSat
            text: qsTr("No data")
            Layout.maximumHeight: 15
            Layout.minimumHeight: 15
            font.pixelSize: 12
            Layout.fillWidth: true
        }

        Text {
            id: elementHdopTitle
            text: qsTr("HDOP")
            Layout.minimumWidth: 80
            Layout.maximumWidth: 80
            Layout.maximumHeight: 15
            Layout.minimumHeight: 15
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
        }

        Text {
            id: elementHdop
            text: qsTr("No data")
            Layout.maximumHeight: 15
            Layout.minimumHeight: 15
            font.pixelSize: 12
            Layout.fillWidth: true
        }

        Text {
            id: elementSpeedTitle
            text: qsTr("Speed")
            Layout.minimumWidth: 80
            Layout.maximumWidth: 80
            Layout.maximumHeight: 15
            Layout.minimumHeight: 15
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
        }

        Text {
            id: elementSpeed
            text: qsTr("No data")
            Layout.maximumHeight: 15
            Layout.minimumHeight: 15
            font.pixelSize: 12
            Layout.fillWidth: true
        }

        Text {
            id: elementTrackTrueTitle
            text: qsTr("Track True")
            Layout.maximumWidth: 80
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
            Layout.minimumHeight: 15
            Layout.maximumHeight: 15
            Layout.minimumWidth: 80
        }

        Text {
            id: elementTrackTrue
            text: qsTr("No data")
            font.pixelSize: 12
            Layout.fillWidth: true
            Layout.minimumHeight: 15
            Layout.maximumHeight: 15
        }

        Text {
            id: elementTrackMagTitle
            text: qsTr("Track Mag")
            Layout.maximumWidth: 80
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
            Layout.minimumHeight: 15
            Layout.minimumWidth: 80
            Layout.maximumHeight: 15
        }

        Text {
            id: elementTrackMag
            text: qsTr("No data")
            font.pixelSize: 12
            Layout.fillWidth: true
            Layout.minimumHeight: 15
            Layout.maximumHeight: 15
        }

        Text {
            id: elementMagVarTitle
            text: qsTr("Mag variation")
            Layout.maximumWidth: 80
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
            Layout.minimumHeight: 15
            Layout.maximumHeight: 15
            Layout.minimumWidth: 80
        }

        Text {
            id: elementMagVar
            text: qsTr("No data")
            font.pixelSize: 12
            Layout.fillWidth: true
            Layout.minimumHeight: 15
            Layout.maximumHeight: 15
        }
    }
}
