// Pegasus Frontend

#pragma once

#include <QString>
#include <QList>
#include <vector>
#include <QFile>
//for DOM xml usage
#include <QDomDocument>
#include <QDomElement>
#include <QDomAttr>


/* #example of es_input.cfg
<?xml version="1.0"?>
<inputList>
	<inputConfig type="joystick" deviceName="X360 Wireless Controller" deviceGUID="030000005e040000a102000000010000" deviceNbAxes="4" deviceNbHats="1" deviceNbButtons="17">
		<input name="joystick2up" type="axis" id="3" value="-1" code="4" />
		<input name="joystick2left" type="axis" id="2" value="-1" code="3" />
		<input name="joystick1up" type="axis" id="1" value="-1" code="1" />
		<input name="joystick1left" type="axis" id="0" value="-1" code="0" />
		<input name="left" type="hat" id="0" value="8" code="16" />
		<input name="down" type="hat" id="0" value="4" code="16" />
		<input name="right" type="hat" id="0" value="2" code="16" />
		<input name="up" type="hat" id="0" value="1" code="16" />
		<input name="r3" type="button" id="12" value="1" code="318" />
		<input name="l3" type="button" id="11" value="1" code="317" />
		<input name="r2" type="button" id="7" value="1" code="313" />
		<input name="l2" type="button" id="6" value="1" code="312" />
		<input name="r1" type="button" id="5" value="1" code="311" />
		<input name="l1" type="button" id="4" value="1" code="310" />
		<input name="y" type="button" id="2" value="1" code="307" />
		<input name="x" type="button" id="3" value="1" code="308" />
		<input name="b" type="button" id="0" value="1" code="304" />
		<input name="a" type="button" id="1" value="1" code="305" />
		<input name="hotkey" type="button" id="8" value="1" code="314" />
		<input name="select" type="button" id="8" value="1" code="314" />
		<input name="start" type="button" id="9" value="1" code="315" />
	</inputConfig>
</inputList> 
*/

namespace providers {
namespace es2 {

struct inputConfigAttribut {
    QString type;
    QString deviceName;
    QString deviceGUID;
    QString deviceNbAxes;
    QString deviceNbHats;
    QString deviceNbButtons;
};

struct inputAttribut {
    QString name;
    QString type;
    QString id;
    QString value;
    QString code;
};

struct inputConfigEntry {
    inputConfigAttribut inputConfigAttributs;
    QList <inputAttribut> inputElements;
};

inputConfigEntry find_input(const QString&, const std::vector<QString>&, const QString&, const QString&);
bool save_input(const QString&, QFile&, inputConfigEntry&);

// for future if needed: bool delete_input(const QString&, QFile&, inputConfigEntry&);


} // namespace es2
} // namespace providers
