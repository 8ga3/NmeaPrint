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
#include "serialport.h"

#include <QSerialPort>
#include <QSerialPortInfo>
#include <QTime>
#include <QDebug>

SerialPort::SerialPort(QObject *parent) : QThread(parent)
{
    const std::initializer_list<QSerialPort::BaudRate> all_BaudRate = {
        QSerialPort::Baud1200,
        QSerialPort::Baud2400,
        QSerialPort::Baud4800,
        QSerialPort::Baud9600,
        QSerialPort::Baud19200,
        QSerialPort::Baud38400,
        QSerialPort::Baud57600,
        QSerialPort::Baud115200
    };

    for (auto rate : all_BaudRate) {
        m_baudratelist.append(rate);
    }
}

SerialPort::~SerialPort()
{
    stopReading();
}

QList<QString> SerialPort::comlist()
{
    m_comlist.clear();

    foreach( const QSerialPortInfo info, QSerialPortInfo::availablePorts() )
    {
//        qDebug() << "Name        :" << info.portName();
//        qDebug() << "Description :" << info.description();
//        qDebug() << "Manufacturer:" << info.manufacturer();

        m_comlist.append(info.portName());
    }

    return m_comlist;
}

QList<qreal> SerialPort::baudratelist()
{
    return m_baudratelist;
}

void SerialPort::startSlot(const QString &device, int baudrate)
{
    qDebug() << "SerialPort::startSlot: " << device << " Baudrate: " << baudrate;
    startReading(device, baudrate);
}

void SerialPort::stopSlot()
{
    qDebug() << "SerialPort::stopSlot";
    stopReading();
}

void SerialPort::startReading(const QString &portName, int baudrate, int waitTimeout)
{
    const QMutexLocker locker(&m_mutex);
    m_quit = false;
    m_portName = portName;
    m_baudrate = static_cast<QSerialPort::BaudRate>(baudrate);
    m_waitTimeout = waitTimeout;
    if (!isRunning())
        start();
}

void SerialPort::stopReading()
{
    m_mutex.lock();
    m_quit = true;
    m_mutex.unlock();
    wait();
}

void SerialPort::run()
{
    bool currentPortNameChanged = false;

    m_mutex.lock();
    QString currentPortName;
    QSerialPort::BaudRate currentBaudrate;
    if (currentPortName != m_portName) {
        currentPortName = m_portName;
        currentBaudrate = m_baudrate;
        currentPortNameChanged = true;
    }

    int currentWaitTimeout = m_waitTimeout;
    m_mutex.unlock();
    QSerialPort serial;

    while (!m_quit) {
        if (currentPortNameChanged) {
            serial.close();
            serial.setPortName(currentPortName);
            serial.setBaudRate(currentBaudrate);
            serial.setDataBits(QSerialPort::Data8);
            serial.setParity(  QSerialPort::NoParity);
            serial.setStopBits(QSerialPort::OneStop);

            if (!serial.open(QIODevice::ReadWrite)) {
                emit error(tr("Can't open %1, error code %2").arg(m_portName).arg(serial.error()));
                return;
            }
        }

        if (serial.waitForReadyRead(currentWaitTimeout)) {
            // read request
            QByteArray requestData = serial.readAll();
            while (serial.waitForReadyRead(10))
                requestData += serial.readAll();
            const QString request = QString::fromUtf8(requestData);
            emit this->request(request);
        } else {
            emit timeout(tr("Wait read request timeout %1").arg(QTime::currentTime().toString()));
        }

        m_mutex.lock();
        if (currentPortName != m_portName) {
            currentPortName = m_portName;
            currentPortNameChanged = true;
        } else {
            currentPortNameChanged = false;
        }
        currentWaitTimeout = m_waitTimeout;
        m_mutex.unlock();
    }
}
