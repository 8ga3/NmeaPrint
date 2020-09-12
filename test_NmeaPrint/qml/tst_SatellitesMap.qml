import QtQuick 2.0
import QtTest 1.1
import "../../NmeaPrint/componets"

Rectangle {
    id: root
    width: 480
    height: 480
    color: "#444444"

    SatellitesMap {
        id: satellitesMap
        radius: height / 2
        color: "#aaaaaa"
        anchors.fill: parent
        lineColor: "black"
        textColor: "black"
    }

    SignalSpy {
        id: spy
        target: satellitesMap
    }

    TestCase {
        name: "SatellitesMap"
        when: windowShown

        function test_satellites_disp() {
            let satellites = {
                "1": [{
                        "svid": 1,
                        "elev": 0,
                        "azimuth": 0,
                        "cno": 45
                    }, {
                        "svid": 2,
                        "elev": 0,
                        "azimuth": 90,
                        "cno": 45
                    }, {
                        "svid": 3,
                        "elev": 0,
                        "azimuth": 180,
                        "cno": 45
                    }, {
                        "svid": 4,
                        "elev": 0,
                        "azimuth": 270,
                        "cno": 45
                    }],
                "2": [{
                        "svid": 70,
                        "elev": 45,
                        "azimuth": 45,
                        "cno": 0
                    }, {
                        "svid": 71,
                        "elev": 45,
                        "azimuth": 135,
                        "cno": 10
                    }, {
                        "svid": 72,
                        "elev": 45,
                        "azimuth": 225,
                        "cno": 20
                    }, {
                        "svid": 73,
                        "elev": 45,
                        "azimuth": 315,
                        "cno": 30
                    }],
                "3": [{
                        "svid": 180,
                        "elev": 85,
                        "azimuth": 45,
                        "cno": 0
                    }, {
                        "svid": 181,
                        "elev": 85,
                        "azimuth": 135,
                        "cno": 10
                    }, {
                        "svid": 182,
                        "elev": 85,
                        "azimuth": 225,
                        "cno": 20
                    }, {
                        "svid": 183,
                        "elev": 85,
                        "azimuth": 315,
                        "cno": 30
                    }]
            }

            let gsa = [{
                           "modeMA": 'A',
                           "mode123": 3,
                           "svid": [1, 3],
                           "pdop": 1.0,
                           "hdop": 2.0,
                           "vdop": 3.0,
                           "gsid": 1
                       }, {
                           "modeMA": 'A',
                           "mode123": 3,
                           "svid": [70, 72],
                           "pdop": 1.0,
                           "hdop": 2.0,
                           "vdop": 3.0,
                           "gsid": 2
                       }, {
                           "modeMA": 'A',
                           "mode123": 3,
                           "svid": [181, 183],
                           "pdop": 1.0,
                           "hdop": 2.0,
                           "vdop": 3.0,
                           "gsid": 3
                       }]

            satellitesMap.updateSatellites(satellites, gsa)
            wait(5000)

            // Retina DisplayのようなHighDPIだと、縦横1/2サイズで保存されるようだ
            // var image = grabImage(satellitesMap)
            // image.save('/tmp/debug.png')
        }
    }
}
