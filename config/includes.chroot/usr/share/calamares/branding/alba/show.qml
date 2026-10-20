/* Alba Linux - presentazione durante l'installazione */
import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    Timer {
        id: avanza
        interval: 7000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    function onActivate() { presentation.currentSlide = 0; }
    function onLeave() { }

    Slide {
        Rectangle { anchors.fill: parent; color: "#14162a" }
        Image { id: logo1; source: "logo.png"; width: 120; height: 120; fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: parent.height * 0.18 }
        Text { anchors.top: logo1.bottom; anchors.topMargin: 28; anchors.horizontalCenter: parent.horizontalCenter
               color: "#ffffff"; font.pixelSize: 26; font.bold: true; text: "Sto installando Alba" }
        Text { anchors.top: logo1.bottom; anchors.topMargin: 72; anchors.horizontalCenter: parent.horizontalCenter
               width: parent.width * 0.7; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
               color: "#c9cbe0"; font.pixelSize: 16
               text: "Ci vuole qualche minuto. Al termine togli la chiavetta: al primo avvio scegli il tuo nome e la password." }
    }
    Slide {
        Rectangle { anchors.fill: parent; color: "#14162a" }
        Text { anchors.centerIn: parent; width: parent.width * 0.7; horizontalAlignment: Text.AlignHCenter
               wrapMode: Text.WordWrap; color: "#ffffff"; font.pixelSize: 22
               text: "I programmi Windows (.exe) si aprono con un doppio clic.\nSteam e i giochi usano da soli la scheda grafica più potente." }
    }
    Slide {
        Rectangle { anchors.fill: parent; color: "#14162a" }
        Text { anchors.centerIn: parent; width: parent.width * 0.7; horizontalAlignment: Text.AlignHCenter
               wrapMode: Text.WordWrap; color: "#ffffff"; font.pixelSize: 22
               text: "Gli aggiornamenti arrivano da soli e si installano al riavvio.\nTutto si regola da Impostazioni, senza terminale." }
    }
}
