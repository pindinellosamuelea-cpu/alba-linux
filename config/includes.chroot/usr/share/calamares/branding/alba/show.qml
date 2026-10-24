/* Alba Linux 1.2 - diapositive durante l'installazione (stile chiaro, nuova grafica).
   Le immagini scorrono con una dissolvenza morbida; sotto, Calamares mostra
   la barra di avanzamento. */
import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation
    property int attuale: 0
    property var immagini: ["diapositiva1.jpg", "diapositiva2.jpg", "diapositiva3.jpg", "diapositiva4.jpg", "diapositiva5.jpg"]

    Timer {
        interval: 8000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.attuale = (presentation.attuale + 1) % presentation.immagini.length
    }

    function onActivate() { presentation.attuale = 0; }
    function onLeave() { }

    Slide {
        Rectangle { anchors.fill: parent; color: "#fbf7f3" }
        Repeater {
            model: presentation.immagini.length
            Image {
                anchors.fill: parent
                source: presentation.immagini[index]
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
                opacity: index === presentation.attuale ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutQuad } }
            }
        }
    }
}
