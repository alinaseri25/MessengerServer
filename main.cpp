#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickView>
#include <QQmlContext>
#include <QDebug>

#include "backend.h"
#include "version.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setWindowIcon(QIcon(":/icons/icon.png"));

    qDebug() << "version : " << app.applicationVersion();
    qDebug() << "Version:" << VERSION_STRING;
    qDebug() << "Version Code:" << VERSION_CODE;

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
