#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickView>
#include <QQmlContext>
#include <QDebug>
#include <QQuickStyle>

//----- this part for debug
#include <QFile>
#include <QTextStream>
#include <QDateTime>
//-----

#include "backend.h"
#include "version.h"

QFile file;

void myMessageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg);

int main(int argc, char *argv[])
{
    QQuickStyle::setStyle("Fusion");
    file.setFileName(QString("log %1.txt").arg(QDateTime::currentDateTime().toMSecsSinceEpoch()));
    //qInstallMessageHandler(myMessageHandler);

    QGuiApplication app(argc, argv);

    app.setWindowIcon(QIcon(":/icons/icon.png"));

    app.setApplicationVersion(VERSION_STRING);
    qDebug() << "version : " << app.applicationVersion();
    qDebug() << "Version:" << VERSION_STRING;
    qDebug() << "Version Code:" << VERSION_CODE;

    qDebug() << "Build :" << QSslSocket::sslLibraryBuildVersionString();
    qDebug() << "Runtime:" << QSslSocket::sslLibraryVersionString();
    qDebug() << "Plugins paths:" << QCoreApplication::libraryPaths();
    qDebug() << "App dir:" << QCoreApplication::applicationDirPath();
    qDebug() << "PATH:" << qEnvironmentVariable("PATH");

    backend *myBackend = new backend(nullptr);

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("myBackend",myBackend);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("MessengerServer", "Main");

    return app.exec();
}

void myMessageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    //QFile file(QString("log %1.txt").arg(QDateTime::currentDateTime().toMSecsSinceEpoch()));
    if(!file.isOpen())
    {
        if(!file.open(QIODevice::Append))
        {
            return;
        }
    }

    QTextStream out(&file);
    out << QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss ");

    switch (type) {
    case QtDebugMsg:
        out << "[DEBUG] ";
        break;
    case QtWarningMsg:
        out << "[WARN ] ";
        break;
    case QtCriticalMsg:
        out << "[ERROR] ";
        break;
    case QtFatalMsg:
        out << "[FATAL] ";
        break;
    case QtInfoMsg:
        break;
    }

    out << msg << "\n";

    file.close();
}
