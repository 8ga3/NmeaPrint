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
  * @file nmea.js
  * @brief NMEA 0183 Standard Version 4.xx をパース
  * @author Masaru Ebata
  * @date 2020/08/18
  * @details NMEAフォーマット・データをパースします。
  */

class NMEA {
    constructor(str) {
        /// GNSS UTC Time: hour
        this.hour = 0;
        /// GNSS UTC Time: minite
        this.minite = 0;
        /// GNSS UTC Time: second
        this.secound = 0;
        /// GNSS UTC Time: milisecond
        this.millisecond = 0;

        /// Latitude 緯度
        this.lat = NaN;
        /// N:North, S:South
        this.lat_ns = "";
        /// Longitude 経度
        this.lon = NaN;
        /// E:East, W:West
        this.lon_ew = "";

        /// 位置特定品質 qualityDesc()で文字列化
        this.quality = 0;
        /// satellites_num数（受信衛星数）
        this.satellites_num = 0;
        /// HDOP (水平精度低下率)
        this.hdop = 99.99;
        /// アンテナの海抜高さ
        this.altitude = NaN;
        /// アンテナの海抜高さ（M:単位）
        this.altitude_unit = "M";
        /// ジオイド高さ
        this.geiod = NaN;
        /// ジオイド高さ（M:単位）
        this.geiod_unit = "M";
        /// DGPSデータの最後の有効なRTCM通信からの時間
        this.dgps_age = NaN;
        /// 差動基準地点ID（ないときもある）
        this.id = "";

        /// 速度[knot]
        this.speedk = NaN;
        /// 地表における移動の真方位
        this.trackTrue = NaN;
        /// 地表における移動の磁方位
        this.trackMag = NaN;
        /// UTC Date: day
        this.day = 1;
        /// UTC Date: month
        this.month = 1;
        /// UTC Date: year
        this.year = 0;
        /// 磁北と真北の間の角度の差Magnetic variation
        this.magVar = NaN;
        /// 磁北と真北の間の角度の差の方向 (E=東, W=西)
        this.varDir = "";
        // モード, N = データなし, A = Autonomous（自律方式）, D = Differential（干渉測位方式）, E = Estimated（推定）, M = Manual input
        this.modeInd = "N";

        /// GNSS DOP and active satellites. Index:Zero-based number
        /// {
        ///     modeMA: モードMA,
        ///     mode123: モード123,
        ///     svid: 衛星番号 (最大12個の配列),
        ///     pdop: 位置精度低下率,
        ///     hdop: 水平精度低下率,
        ///     vdop: 垂直精度低下率,
        ///     gsid: GNSS system ID
        /// }
        this.gsa = [];

        /// Satellite position and signal strength. Index:TalkerID
        /// {
        ///     svid: 衛星番号,
        ///     elev: 仰角,
        ///     azimuth: 方位角,
        ///     cno: 信号強度 (0-99 dB)
        /// }
        this.satellites = {};

        const messages = str.split('\r\n');

        for (const msg of messages) {
            if (msg.length === 0) {
                continue;
            }

            const arr = msg.split('*');
            const content = arr[0];
            const checksum = arr[1];
            const c1 = NMEA.getCheckSum(content);
            const c2 = parseInt(checksum, 16)

            if (c1 !== c2) {
                console.log("check sum error.");
                continue;
            }

            // console.log(content);

            switch (true) {
                case /^\$G.GGA/.test(content):
                    this.parseGga(content);
                    break;
                case /^\$G.RMC/.test(content):
                    this.parseRmc(content);
                    break;
                case /^\$G.VTG/.test(content):
                    this.parseVtg(content);
                    break;
                case /^\$G.GSA/.test(content):
                    this.parseGsa(content);
                    break;
                case /^\$G.GSV/.test(content):
                    this.parseGsv(content);
                    break;
            }
        }

        this.reassignGsid();
    }

    /**
     * 経緯度 度分(nnnmm.mmm)を度(nn.nnnn...)へ変換
     * ※小数点以下は秒ではなく分(1/60)の少数点表記
     * @param deg 経緯度 度分(nnnmm.mmm)
     */
    static milli2dec(deg) {
        let n = Math.floor(deg / 100);
        let m = (deg - n * 100) / 60;
        return n + m;
    }

    /**
     * $から*の間を排他的論理和をとる
     * ASCIIコードを使用
     * @param str message string
     */
    static getCheckSum(str) {
        let checksum = 0;
        for (let c = 1; c < str.length; c++) {
            checksum = checksum ^ str.charCodeAt(c);
        }
        return checksum;
    }

    /**
     * Taker IDを判別
     * @param str header string
     */
    static checkTakerID(str) {
        let id;
        let talkerid = str.substr(1, 2);
        switch (talkerid) {
            case "GN": // 複数の衛星システムを利用して測位している場合
                id = 0;
                break;
            case "GP": // GPS
                id = 1;
                break;
            case "GL": // GLONASS
                id  = 2;
                break;
            case "GA": // Galileo
                id = 3;
                break;
            case "GB": // BeiDou
            case "BD": // BeiDou (legacy ID)
                id = 4;
                break;
            case "GQ": // QZSS (192を引く。QZS-1=1, QZS-2=2, QZS-3=7, QZS-4=3) センサーによってはGPに統合される。
            case "QZ": // QZSS (legacy ID)
                id = 5;
                break;
            case "SB": // SBAS?
            case "SV": // SBAS?
                id = 6;
                break;
            case "IM": // IMES
                id = 7;
                break;
            case "GI": // NavIC (IRNSS)
                id = 8;
                break;
            default:
                id = -1;
                break;
        }

        return id;
    }

    /**
     * GNGSA（Taker IDがGN）と出力するセンサーは、
     * GSVが出力される順番のGNSS System IDを振り直す
     */
    reassignGsid() {
        for (let i = 0; i < this.gsa.length; i++) {
            if (this.gsa[i].gsid === 0) {
                let keys = Object.keys(this.satellites);
                if (i < keys.length) {
                    let gsid = parseInt(keys[i]);
                    this.gsa[i].gsid = gsid;
                }
            }
        }
    }

    /**
     * 位置特定品質
     */
    qualityDesc() {
        const strings = [
            "Not fix",      // 0 ： 利用できない、無効
            "SPS fix",      // 1 ： SPS（標準測位サービス）モード
            "DGPS fix",     // 2 ： differenctial GPS（干渉測位方式）モード
            "GPS-PPS",      // 3 ： GPS-PPS
            "RTK fix",      // 4 ： Real Time Kinematic. System used in RTK mode with fixed integers
            "RTK float",    // 5 ： Float RTK. satellites system used in RTK mode, floating integers
            "Estimated",    // 6 ： Estimated (dead reckoning) mode
            "Manual",       // 7 ： マニュアル入力モード
            "Simulation"    // 8 ： シミュレーションモード
        ];

        if (this.quality >= 0 && this.quality <= 8) {
            return strings[this.quality];
        }
        else {
            return "undefined";
        }
    }

    /**
     * GGA: Global positioning system fix data
     * @param str message string
     */
    parseGga(str) {
        let parts = str.split(',');

        // 時刻
        let time = parts[1];
        if (time.length) {
            this.hour = parseInt(time.substr(0, 2));
            this.minite = parseInt(time.substr(2, 2));
            this.secound = parseInt(time.substr(4, 2));
            let ms = time.substr(7);
            this.millisecond = parseInt(ms);
            if (ms.length === 2)
                this.millisecond *= 10;
        }

        // 経緯度
        if (parts[2].length > 0 && parts[4].length > 0) {
            this.lat = NMEA.milli2dec(parseFloat(parts[2]));
            this.lat_ns = parts[3];
            this.lon = NMEA.milli2dec(parseFloat(parts[4]));
            this.lon_ew = parts[5];
        }

        // 位置特定品質
        this.quality = parseInt(parts[6]);
        // satellites_num数（受信衛星数）
        this.satellites_num = parseInt(parts[7]);
        // HDOP (水平精度低下率)
        this.hdop = parseFloat(parts[8]);
        // アンテナの海抜高さ
        this.altitude = parseFloat(parts[9]);
        // アンテナの海抜高さ（M:単位）
        this.altitude_unit = parts[10];
        // ジオイド高さ
        this.geiod = parseFloat(parts[11]);
        // ジオイド高さ（M:単位）
        this.geiod_unit = parts[12];
        // DGPSデータの最後の有効なRTCM通信からの時間
        this.dgps_age = parts[13];
        // 差動基準地点ID（ないときもある）
        this.id = parts[14];
    }

    /**
     * RMC: Recommended minimum data
     * @param str message string
     */
    parseRmc(str) {
        let parts = str.split(',');

        // 時刻
        let time = parts[1];
        if (time.length) {
            this.hour = parseInt(time.substr(0, 2));
            this.minite = parseInt(time.substr(2, 2));
            this.secound = parseInt(time.substr(4, 2));
            let ms = time.substr(7);
            this.millisecond = parseInt(ms);
            if (ms.length === 2)
                this.millisecond *= 10;
        }

        // ステータス
        // parts[2]

        // 経緯度
        if (parts[3].length > 0 && parts[5].length > 0) {
            this.lat = NMEA.milli2dec(parseFloat(parts[3]));
            this.lat_ns = parts[4];
            this.lon = NMEA.milli2dec(parseFloat(parts[5]));
            this.lon_ew = parts[6];
        }

        // 速度[knot]
        this.speedk = parseFloat(parts[7]);
        // 地表における移動の真方位
        this.trackTrue = parseFloat(parts[8]);
        // 日付(UTC)
        let date = parts[9];
        if (date.length) {
            this.day = parseInt(date.substr(0, 2));
            this.month = parseInt(date.substr(2, 2));
            this.year = 2000 + parseInt(date.substr(4, 2));
        }
        // 磁北と真北の間の角度の差Magnetic variation
        this.magVar = parseFloat(parts[10]);
        // 磁北と真北の間の角度の差の方向 (E=東, W=西)
        this.varDir = parts[11];
        // モード, N = データなし, A = Autonomous（自律方式）, D = Differential（干渉測位方式）, E = Estimated（推定）, M = Manual input
        this.modeInd = parts[12];
    }

    /**
     * VTG: Course over ground and ground speed
     * @param str message string
     */
    parseVtg(str) {
        let parts = str.split(',');

        // 地表における移動の真方位
        this.trackTrue = parseFloat(parts[1]);
        // True course indicator (T)
        // parts[2]
        // 地表における移動の磁方位
        this.trackMag = parseFloat(parts[3]);
        // Magnetic track indicator (M)
        // parts[4]
        // 速度[knot]
        this.speedk = parseFloat(parts[5]);
        // Nautical speed indicator (N = Knots)
        // parts[6]
        // 時速 km/h
        this.speed = parseFloat(parts[7]);
        // Speed indicator (K = km/hr)
        // parts[8]
        // モード, N = データなし, A = Autonomous（自律方式）, D = Differential（干渉測位方式）, E = Estimated（推定）, M = Manual input
        this.modeInd = parts[9];
    }

    /**
     * GSA: GNSS DOP and active satellites
     * @param str message string
     */
    parseGsa(str) {
        let parts = str.split(',');

        if (parts.length < 18)
            return;

        // モードMA
        let modeMA = parts[1];
        // モード123
        let mode123 = parseInt(parts[2]);

        let svid = [];
        // 衛星番号 最大12個
        for (let i = 3; i < 15; i++) {
            if (parts[i].length === 0) {
                break;
            }
            svid.push(parseInt(parts[i]));
        }

        // 位置精度低下率
        let pdop = parseFloat(parts[15]);
        // 水平精度低下率
        let hdop = parseFloat(parts[16]);
        // 垂直精度低下率
        let vdop = parseFloat(parts[17]);

        let gsid = NMEA.checkTakerID(parts[0]);

        // GNSS system ID, value is 1 (GPS), 2 (GLONASS), 3 (GALILEO), 4 or 5 (BEIDOU), 5 or 15 (QZSS)
        // talker idがGNでGSIDがあれば決定
        // GNSS機器によってGSIDに違いがありそう
        // GSIDがない場合は、GSVの順番で判定
        if (gsid === 0 && parts.length > 18 && parts[18].length > 0) {
            gsid = parseInt(parts[18]);
        }

        let gsa = {
            modeMA: modeMA,
            mode123: mode123,
            svid: svid,
            pdop: pdop,
            hdop: hdop,
            vdop: vdop,
            gsid: gsid
        }

        this.gsa.push(gsa);
    }

    /**
     * GSV: GPS satellites_num in view
     * @param str message string
     */
    parseGsv(str) {
        let parts = str.split(',');

        if (parts.length < 4) {
            return;
        }

        let gsid = NMEA.checkTakerID(parts[0]);
        if (gsid === 0) {
            return;
        }
        let type = String(gsid);

        // Total number of messages (1-9)
        let totalnum = parseInt(parts[1]);

        // Message number (1-9)
        let msgnum = parseInt(parts[2]);

        // Total number of satellites_num in view.
        let sats = parseInt(parts[3]);

        for (let i = 0; i < 4; i++) {

            if (parts.length < 4 + 4 + i * 4) {
                break;
            }

            // satellites ID
            // GPS = 1 to 32
            // SBAS = 33 to 64 (add 87 for PRN#s)
            // GLO = 65 to 96
            let tmp = parts[4 + i*4 + 0];
            if (tmp.length === 0) {
                break;
            }
            let svid = parseInt(tmp);
            // Elevation in degrees (range: 0-90)
            tmp = parts[4 + i*4 + 1];
            let elev = tmp.length > 0 ? parseInt(tmp) : NaN;
            // Azimuth (range: 0-359, degrees from true north)
            tmp = parts[4 + i*4 + 2];
            let azimuth = tmp.length > 0 ? parseInt(tmp) : NaN;
            // Signal strength (C/No, range: 0-99 dB), null when not tracking
            tmp = parts[4 + i*4 + 3]
            let cno = tmp.length > 0 ? parseInt(parts[4 + i*4 + 3]) : NaN;

            let sat = {
                svid: svid,
                elev: elev,
                azimuth: azimuth,
                cno: cno
            }

            if (type in this.satellites) {
                this.satellites[type].push(sat);
            }
            else {
                this.satellites[type] = [sat];
            }
        }

        if (!(type in this.satellites)) {
            this.satellites[type] = [];
        }

        // NMEA-defined GNSS signal ID, see Signal Identifiers table
        // (only available in NMEA 4.10 and later)
        if (parts.length >= 21) {
            let signalId = parseInt(parts[20]);
        }
    }

    /**
     * ZDA: Time and Date
     * Unimplemented
     * @param str message string
     */
    parseZda(str) {
    }

    /**
     * GLL: Latitude and longitude, with time of position fix and status
     * Unimplemented
     * @param str message string
     */
    parseGll(str) {
    }
}
