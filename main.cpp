#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickView>
#include <QQmlContext>
#include <QDebug>

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
    file.setFileName(QString("log %1.txt").arg(QDateTime::currentDateTime().toMSecsSinceEpoch()));
    qInstallMessageHandler(myMessageHandler);

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

    QQuickView viewer;

    viewer.rootContext()->setContextProperty("myBackend",myBackend);

#ifdef Q_OS_WIN
    QString extraImportPath(QStringLiteral("%1/../../../../%2"));
#else
    QString extraImportPath(QStringLiteral("%1/../../../%2"));
#endif
    viewer.engine()->addImportPath(extraImportPath.arg(QGuiApplication::applicationDirPath(),
                                                       QString::fromLatin1("qml")));
    QObject::connect(viewer.engine(), &QQmlEngine::quit, &viewer, &QWindow::close);

    viewer.setTitle(QStringLiteral("messenger Server"));
    viewer.setSource(QUrl("qrc:/Main.qml"));
    viewer.setResizeMode(QQuickView::SizeRootObjectToView);

    viewer.show();

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
