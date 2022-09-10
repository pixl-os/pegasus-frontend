#ifndef KEYEMITTER_H
#define KEYEMITTER_H
#include <QObject>
#include <QCoreApplication>
#include <QKeyEvent>

class KeyEmitter : public QObject
{
    Q_OBJECT
public:
    
    KeyEmitter(QObject* parent=nullptr) : QObject(parent) {}
    
    Q_INVOKABLE void keyPressed(QObject* tf, Qt::Key k, Qt::KeyboardModifiers m=Qt::NoModifier) {
        QKeyEvent keyPressEvent = QKeyEvent(QEvent::Type::KeyPress, k, m, QKeySequence(k).toString());
        QCoreApplication::sendEvent(tf, &keyPressEvent);
    }

    Q_INVOKABLE void keyReleased(QObject* tf, Qt::Key k, Qt::KeyboardModifiers m=Qt::NoModifier) {
        QKeyEvent keyReleaseEvent = QKeyEvent(QEvent::Type::KeyRelease, k, m, QKeySequence(k).toString());
        QCoreApplication::sendEvent(tf, &keyReleaseEvent);
    }

};
#endif // KEYEMITTER_H
