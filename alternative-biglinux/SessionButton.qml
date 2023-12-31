/*
 *   Copyright 2016 David Edmundson <davidedmundson@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.2

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import QtQuick.Controls.Styles 1.4 as QQCS
import QtQuick.Controls 1.3 as QQC

PlasmaComponents.ToolButton {
    id: root
    property int currentIndex: -1
    
    implicitHeight: units.gridUnit * 1.5
    
    visible: menu.items.length > 1
    style: QQCS.ButtonStyle {
        label: QQC.Label {
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    color: "#fff"
                    font.pointSize: 12
                    text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Selecione o desktop: %1", instantiator.objectAt(currentIndex).text || "")
                    padding: 10
                }
        background: Rectangle {
            color: "#ccc"
            border.width: 1
            border.color : "#fff"
            opacity: 0.3
            radius: 15
        }
    }
    Component.onCompleted: {
        currentIndex = sessionModel.lastIndex
    }

    menu: QQC.Menu {
        id: menu
        style: MenuStyle {
        }
        
        Instantiator {
            id: instantiator
            model: sessionModel
            onObjectAdded: menu.insertItem(index, object)
            onObjectRemoved: menu.removeItem( object )
            delegate: QQC.MenuItem {
                text: model.name
                onTriggered: {
                    root.currentIndex = model.index
                }
            }
        }
    }
}
