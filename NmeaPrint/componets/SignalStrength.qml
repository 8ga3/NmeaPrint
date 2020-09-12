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
  * @file SignalStrength.qml
  * @brief GNSS衛星のキャリア／ノイズ比のバーグラフ
  * @author Masaru Ebata
  * @date 2020/08/18
  * @details nmea.jsでパースしたNMEAフォーマット・データから、GNSS衛星のキャリア／ノイズ比をバーグラフで表示します。表示エリアに合わせてバーの幅を調整します。
  */

import QtQuick 2.0
import QtQuick.Shapes 1.0

Item {
    id: root

    /// バーのマージンサイズ [pixel]
    property int barMargin: 4
    /// バーの最大幅 [pixel]
    property int maxWidth: 100
    /// 最大フォントサイズ [pixel]
    property int maxFontSize: 18
    /// キャリア／ノイズ比の最大値 [dB]
    property int maxdB: 55
    /// 座標計算で使用するGNSS衛星のバーの色
    property color enableColor: "#66eeff"
    /// 座標計算で未使用のGNSS衛星のバーの色
    property color disableColor: "#dddddd"
    /// グラフ毎に表示する文字色
    property color textColor: "Black"
    /// グラフ縦軸の補助目盛線色
    property color lineColor: "#aaaaaa"

    // 補助目盛線描画
    Repeater {
        model: [0, 10, 20, 30, 40, 50]

        Shape {
            width: root.width
            height: 1
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.height * modelData / root.maxdB
            antialiasing: true

            ShapePath {
                fillColor: "transparent" // stroke only
                strokeColor: root.lineColor
                strokeWidth: 1
                startX: 0
                startY: 0
                PathLine { relativeX: width; relativeY: 0 }
            }
        }
    }

    // バー表示
    Row {
        id: view
        anchors.fill: parent
        spacing: root.barMargin

        property int rows: Math.max(repeater.count, 1)
        property real singleWidth: Math.min((width - root.barMargin * (rows - 1)) / rows, root.maxWidth)

        Component {
            id: bar

            Item {
                width: view.singleWidth
                height: parent.height

                // バーの矩形
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.height * Math.min(modelData.cno, 55) / root.maxdB
                    color: modelData.using ? root.enableColor : root.disableColor
                }

                // バーごとの文字情報
                Column {
                    width: parent.width
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    spacing: 2

                    property real size: Math.max(Math.min(parent.width * 0.4 - 2, root.maxFontSize), 2)

                    // C/No （キャリア／ノイズ比）
                    Text {
                        text: modelData.cno
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        color: root.textColor
                        font.pixelSize: parent.size
                    }

                    // 衛星種別
                    Text {
                        text: modelData.gsid
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        color: root.textColor
                        font.pixelSize: parent.size
                    }

                    // 衛星番号
                    Text {
                        text: modelData.satNo
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        color: root.textColor
                        font.pixelSize: parent.size
                    }
                }
            }
        }

        Repeater {
            id: repeater
            anchors.fill: parent
            delegate: bar
//            model: root.itemElements
        }
    }

    // テスト表示データ
    property var itemElements: [
        { "gsid": "GP", "satNo": "000", "cno": 55, "using": true  },
        { "gsid": "GA", "satNo":  "10", "cno": 50, "using": false },
        { "gsid": "BD", "satNo":  "39", "cno": 20, "using": true  },
        { "gsid": "QZ", "satNo":   "1", "cno":  5, "using": false },
        { "gsid": "GP", "satNo": "000", "cno": 55, "using": true  },
        { "gsid": "GA", "satNo":  "10", "cno": 50, "using": false },
        { "gsid": "BD", "satNo":  "39", "cno": 20, "using": true  },
        { "gsid": "QZ", "satNo":   "1", "cno":  5, "using": false },
        { "gsid": "GP", "satNo": "000", "cno": 55, "using": true  },
        { "gsid": "GA", "satNo":  "10", "cno": 50, "using": false },
        { "gsid": "BD", "satNo":  "39", "cno": 20, "using": true  },
        { "gsid": "QZ", "satNo":   "1", "cno":  5, "using": false },
        { "gsid": "GP", "satNo": "000", "cno": 55, "using": true  },
        { "gsid": "GA", "satNo":  "10", "cno": 50, "using": false },
        { "gsid": "BD", "satNo":  "39", "cno": 20, "using": true  },
        { "gsid": "QZ", "satNo":   "1", "cno":  5, "using": false },
    ]

    /**
      * @brief 電波強度グラフ更新
      * @param satellites nmea.jsのGNSS.satellites
      * @param gsa nmea.jsのGNSS.gsa
      * @details nmea.jsでパースしたNMEAフォーマット・データから、バーグラフを更新します。
      */
    function updateBarGraph(satellites, gsa) {

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

        function getGnssName(gsid) {
            let names = {
                "1":"GPS",
                "2":"GLO",
                "3":"GAL",
                "4":"BEI",
                "5":"QZS",
                "6":"SBA",
                "7":"IME",
                "8":"NAV"
            }

            if (gsid in names) {
                return names[gsid]
            }

            return "?"
        }

        let arr = []

        for (let gsid in satellites) {
            let gsidSats = satellites[gsid]
            let active = searchGsid(gsa, gsid)
            let name = getGnssName(gsid)

            if (!active) {
                continue
            }

            for (let n in gsidSats) {
                let sat = gsidSats[n]

                let param = {
                    "gsid": name,
                    "satNo": sat.svid,
                    "cno": sat.cno,
                    "using": false
                }

                if (searchSvid(active.svid, sat.svid)) {
                    param["using"] = true
                }

                arr.push(param)
            }
        }

        repeater.model = arr
    }
}
