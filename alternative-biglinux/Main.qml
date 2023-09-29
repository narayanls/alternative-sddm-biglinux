/*
 *   Copyright 2016 David Edmundson <davidedmundson@kde.org> 
 *   Copyright 2023 Bruno Gonçalves <bigbruno@gmail.com> - Programmer
 *   Copyright 2023 Douglas Guimarães <dg2003gh@gmail.com> - Programmer
 *   Copyright 2023 Rafael Ruscher <rruscher@gmail.com> - Design UX/UI
 *   
 * This program is free software; you can redistribute it and/or modify
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

import QtQuick 2.8

import QtQuick.Layouts 1.1
import QtQuick.Controls 1.1
import QtQuick.Controls 2.12 as QQC2
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

import "components"

PlasmaCore.ColorScope {
    id: root

    // If we're using software rendering, draw outlines instead of shadows
    // See https://bugs.kde.org/show_bug.cgi?id=398317
    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software
    colorGroup: PlasmaCore.Theme.ComplementaryColorGroup
    readonly property bool lightBackground: Math.max(PlasmaCore.ColorScope.backgroundColor.r, PlasmaCore.ColorScope.backgroundColor.g, PlasmaCore.ColorScope.backgroundColor.b) > 0.5

    width: 1600
    height: 900

    property string notificationMessage

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true
    
    PlasmaCore.DataSource {
        id: keystateSource
        engine: "keystate"
        connectedSources: "Caps Lock"
    }

    Item {
        id: wallpaper
        anchors.fill: parent
        Repeater {
            model: screenModel

            Background {
                x: geometry.x; y: geometry.y; width: geometry.width; height: geometry.height
                sceneBackgroundType: config.type
                sceneBackgroundColor: config.color
                sceneBackgroundImage: config.background
            }
        }
    }
    
    MouseArea {
        id: loginScreenRoot
        anchors.fill: parent

        property bool uiVisible: true
        property bool blockUI: mainStack.depth > 1 || userListComponent.mainPasswordBox.text.length > 0 || inputPanel.keyboardActive || config.type !== "image"

        hoverEnabled: true
        drag.filterChildren: true
        onPressed: uiVisible = true;
        onPositionChanged: uiVisible = true;
        onUiVisibleChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
            } else if (uiVisible) {
                fadeoutTimer.restart();
            }
        }
        onBlockUIChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
                uiVisible = true;
            } else {
                fadeoutTimer.restart();
            }
        }

        Keys.onPressed: {
            uiVisible = true;
            event.accepted = false;
        }

        //takes one full minute for the ui to disappear
        Timer {
            id: fadeoutTimer
            running: true
            
            interval: 60000
            onTriggered: {
                if (!loginScreenRoot.blockUI) {
                    loginScreenRoot.uiVisible = false;
                }
            }
        }
       
       Item {
        anchors.centerIn: parent
        implicitWidth: parent.width / 2.5
        implicitHeight: parent.height / 1.5
        width: Math.max(150, implicitWidth)
        height: Math.max(150, implicitHeight)
        
        Rectangle { 
            id: backgroundBox
            
            anchors.fill: parent
            color: "#000"
            opacity: 0.7
            radius: 15
            
        }

        Battery {
                anchors {
                    top: parent.top
                    topMargin: units.largeSpacing + 2.5
                    right: parent.right
                    rightMargin: units.largeSpacing
                    
                }
        } 
        
        KeyboardButton {
            
        }
        
        Clock {
            id: clock
            visible: y > 0
            anchors.horizontalCenter: parent.horizontalCenter
            y: (userListComponent.userList.y + mainStack.y)/0.7 - height/2
        }
        
        SessionButton{
            id:sessionButton
            
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: phrasesModel.top
                bottomMargin: units.largeSpacing * 2.0
            }
        }
        
        PhrasesModel {
            id: phrasesModel
            anchors{
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: units.gridUnit * 8
            }
        }
        
        Row { 
            id: actionItems
            spacing: units.largeSpacing / 2
            
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: units.largeSpacing 
            }
            
                ActionButton {
                    iconSource: "/usr/share/sddm/themes/biglinux/components/artwork/logout_primary.svg"
                    //text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel","Suspend to RAM","Sleep")
                    onClicked: sddm.suspend()
                    //enabled: sddm.canSuspend 
                    enabled: true //Ruscher
                    visible: !inputPanel.keyboardActive
                }
                ActionButton {
                    iconSource: "/usr/share/sddm/themes/biglinux/components/artwork/restart_primary.svg"
                    //text: i18nd("plasma_lookandfeel_org.kde.lookandfeel","Restart")
                    onClicked: sddm.reboot()
                    //enabled: sddm.canReboot
                    enabled: true //Ruscher
                    visible: !inputPanel.keyboardActive
                }
                ActionButton {
                    iconSource: "/usr/share/sddm/themes/biglinux/components/artwork/shutdown_primary.svg"
                    //text: i18nd("plasma_lookandfeel_org.kde.lookandfeel","Shut Down")
                    onClicked: sddm.powerOff()
                    //enabled: sddm.canPowerOff
                    enabled: true //Ruscher
                    visible: !inputPanel.keyboardActive
                }
        }
    }
    
        StackView {
            id: mainStack
            anchors {
                left: parent.left
                right: parent.right
            }
            
            height: root.height + units.gridUnit * -3
             
            focus: true //StackView is an implicit focus scope, so we need to give this focus so the item inside will have it

            Timer {
                //SDDM has a bug in 0.13 where even though we set the focus on the right item within the window, the window doesn't have focus
                //it is fixed in 6d5b36b28907b16280ff78995fef764bb0c573db which will be 0.14
                //we need to call "window->activate()" *After* it's been shown. We can't control that in QML so we use a shoddy timer
                //it's been this way for all Plasma 5.x without a huge problem
                running: true
                repeat: false
                interval: 200
                onTriggered: mainStack.forceActiveFocus()
            }

            initialItem: Login {
                    id: userListComponent
                    userListModel: userModel
                    loginScreenUiVisible: loginScreenRoot.uiVisible
                    userListCurrentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
                    lastUserName: userModel.lastUser
                    showUserList: {
                        if ( !userListModel.hasOwnProperty("count")
                        || !userListModel.hasOwnProperty("disableAvatarsThreshold"))
                            return (userList.y + mainStack.y) > 0

                        if ( userListModel.count === 0 ) return false

                        if ( userListModel.hasOwnProperty("containsAllUsers") && !userListModel.containsAllUsers ) return false

                        return userListModel.count <= userListModel.disableAvatarsThreshold && (userList.y + mainStack.y) > 0
                    }

                    notificationMessage: {
                        var text = ""
                        if (keystateSource.data["Caps Lock"]["Locked"]) {
                            text += i18nd("plasma_lookandfeel_org.kde.lookandfeel","Caps Lock is on")
                            if (root.notificationMessage) {
                                text += " • "
                            }
                        }
                        text += root.notificationMessage
                        return text
                    }
                    
                    onLoginRequest: {
                        root.notificationMessage = ""
                        sddm.login(username, password, sessionButton.currentIndex)
                    }
                
              }
            }
          }              
  
            Behavior on opacity {
                OpacityAnimator {
                    duration: units.longDuration
                }
            }

        Loader {
            id: inputPanel
            state: "hidden"
            property bool keyboardActive: item ? item.active : false
            onKeyboardActiveChanged: {
                if (keyboardActive) {
                    state = "visible"
                } else {
                    state = "hidden";
                }
            }
            source: "components/VirtualKeyboard.qml"
            anchors {
                left: parent.left
                right: parent.right
            }

            function showHide() {
                state = state == "hidden" ? "visible" : "hidden";
            }

            states: [
                State {
                    name: "visible"
                    PropertyChanges {
                        target: mainStack
                        y: Math.min(0, root.height - inputPanel.height - userListComponent.visibleBoundary)
                    }
                    PropertyChanges {
                        target: inputPanel
                        y: root.height - inputPanel.height
                        opacity: 1
                    }
                },
                State {
                    name: "hidden"
                    PropertyChanges {
                        target: mainStack
                        y: 0
                    }
                    PropertyChanges {
                        target: inputPanel
                        y: root.height - root.height/4
                        opacity: 0
                    }
                }
            ]
            transitions: [
                Transition {
                    from: "hidden"
                    to: "visible"
                    SequentialAnimation {
                        ScriptAction {
                            script: {
                                inputPanel.item.activated = true;
                                Qt.inputMethod.show();
                            }
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: mainStack
                                property: "y"
                                duration: units.longDuration
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: inputPanel
                                property: "y"
                                duration: units.longDuration
                                easing.type: Easing.OutQuad
                            }
                            OpacityAnimator {
                                target: inputPanel
                                duration: units.longDuration
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                },
                Transition {
                    from: "visible"
                    to: "hidden"
                    SequentialAnimation {
                        ParallelAnimation {
                            NumberAnimation {
                                target: mainStack
                                property: "y"
                                duration: units.longDuration
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: inputPanel
                                property: "y"
                                duration: units.longDuration
                                easing.type: Easing.InQuad
                            }
                            OpacityAnimator {
                                target: inputPanel
                                duration: units.longDuration
                                easing.type: Easing.InQuad
                            }
                        }
                        ScriptAction {
                            script: {
                                Qt.inputMethod.hide();
                            }
                        }
                    }
                }
            ]
        }


        Component {
            id: userPromptComponent
            
            Login {
                showUsernamePrompt: true
                notificationMessage: root.notificationMessage
                loginScreenUiVisible: loginScreenRoot.uiVisible
                // using a model rather than a QObject list to avoid QTBUG-75900
                userListModel: ListModel {
                    ListElement {
                        name: ""
                        iconSource: ""
                    }
                    Component.onCompleted: {
                        // as we can't bind inside ListElement
                        setProperty(0, "name", i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Type in Username and Password"));
                    }
                }

                onLoginRequest: {
                    root.notificationMessage = ""
                    sddm.login(username, password, sessionButton.currentIndex)
                }
            }
        }
    Connections {
        target: sddm
        
        onLoginFailed: {
            notificationMessage = i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Login Failed")
            mainStack.enabled = true
            userListComponent.userList.opacity = 1
        }
        onLoginSucceeded: {
            //note SDDM will kill the greeter at some random point after this
            //there is no certainty any transition will finish, it depends on the time it
            //takes to complete the init
            mainStack.opacity = 0
        }
    }

    onNotificationMessageChanged: {
        if (notificationMessage) {
            notificationResetTimer.start();
        }
    }

    Timer {
        id: notificationResetTimer
        interval: 3000
        onTriggered: notificationMessage = ""
    }
}
