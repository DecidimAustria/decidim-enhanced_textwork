# Kriterienkatalog für Textwork

Die 20 Kriterien sind der gemeinsame Maßstab für Gestaltung und Abnahme. Die Bauanleitung verweist mit „Kriterium n" darauf.

Grundlage: **N** Norm (WCAG 2.2 A/AA) · **F** Forschung · **P** dokumentierte Praxis · **H** Hypothese, später zu prüfen. Zahlen unter H sind Startwerte.

Der Katalog ersetzt keine vollständige Konformitätsprüfung nach WCAG 2.2 AA.

| Nr. | Grundlage | Regel | Bedeutung für Textwork |
| --- | --- | --- | --- |
| 1 | P + Vorgabe | Schriftfamilien, Farben, Zustände und Abstände werden aus dem Designsystem der Decidim-Zielversion übernommen. | Keine eigene Markenpalette, keine fest eingebaute Ersatzschrift. Zuordnung gegen Decidim 0.32 prüfen. |
| 2 | F/P/H | Der Dokumenttext hat 18–20 CSS-Pixel bei Standarddarstellung, passend zur vorhandenen Schriftskala. | Projektwert, keine WCAG-Mindestgröße. Der Beteiligungstext ist keine nachrangige Metainformation. |
| 3 | P/H | Fließtext erreicht bei ausreichender Breite überwiegend 55–75 Zeichen je Zeile, linksbündig, ohne Blocksatz. | Gilt auch bei geöffneten Zusatzinformationen. Schmale Bildschirme dürfen kürzere Zeilen ergeben. |
| 4 | P/H | Die Zeilenhöhe des Dokumenttexts startet bei 1,5–1,7 und wird mit der Instanzschrift überprüft. | Lange Absätze müssen bequem verfolgbar sein. |
| 5 | N/F/P | Überschriften beschreiben Inhalt und Gliederung und vermitteln dieselbe Hierarchie visuell wie für assistive Technik. | Dokumentgliederung erhalten. Absatznummern, Abschnittstitel und technische Kennungen nicht verwechseln. |
| 6 | P/H | Abstände innerhalb einer Gruppe sind kleiner als zwischen Gruppen und folgen der vorhandenen Abstandsskala. | Absatz, Aktionen und Metadaten bilden eine Einheit; benachbarte Absätze verschmelzen nicht. |
| 7 | N/P | Farbe wird konsistent für Bedeutung eingesetzt; kein wichtiger Zustand wird nur durch Farbe vermittelt. | Erkennbar bleiben muss, ob ein Absatz nur ausgewählt oder bereits unterstützt wurde. |
| 8 | P/H | Das Inhaltsverzeichnis bildet Reihenfolge und Hierarchie ab und macht den aktuellen Ort erkennbar. | Bezeichnungen im Verzeichnis und im Dokument stimmen überein; lange Titel bleiben zugänglich. |
| 9 | P/H | Nach einem Wechsel zwischen Text, Diskussion und Änderungsvorschlag wird die bearbeitete Stelle zuverlässig wiedergefunden. | Stabile Absatzlinks und ein nachvollziehbarer Rückweg. |
| 10 | P/H | Der vollständige Ausgangstext bleibt zusammenhängend lesbar; ergänzende Informationen öffnen sich bei Bedarf. | Gründliches Lesen ohne Öffnen jedes Absatzes; nicht alle Diskussionen gleichzeitig sichtbar. |
| 11 | P + Vorgabe | Unterstützen, Kommentieren und das Einreichen einer geänderten Absatzfassung sind drei klar benannte, auffindbare Handlungen mit verständlichen Folgen. | Erstteilnehmende müssen die Begriffe nicht kennen. Weder Symbolwissen noch Darüberfahren mit der Maus darf nötig sein. Erklären, was ein Änderungsvorschlag bewirkt. |
| 12 | P/H | Ausgangsfassung, vorgeschlagene Fassung und Entscheidungsstatus sind jederzeit eindeutig unterscheidbar. | Ein Vorschlag ist noch kein gültiger Text. Ergänzungen und Streichungen sind nachvollziehbar. |
| 13 | F/P/H | Kommentare und Änderungsvorschläge behalten einen nachvollziehbaren Bezug zum Absatz und zur maßgeblichen Textfassung. | Ein Beitrag darf nach einer Überarbeitung nicht stillschweigend einem anderen Inhalt zugeordnet werden. |
| 14 | N | Normaler Text mindestens 4,5:1 Kontrast, großer Text 3:1, notwendige Bedien- und Zustandsmerkmale 3:1. | Auch Metadaten, Auswahlzustände und Eingabefelder in den unterstützten Instanzgestaltungen prüfen. |
| 15 | N | Text und Bedienung bleiben bei 200 % Textvergrößerung und bei 320 CSS-Pixel Breite ohne Verlust nutzbar. | Kein Scrollen in zwei Richtungen für gewöhnlichen Text; Textvergleiche auch schmal nutzbar. |
| 16 | N | Individuelle Textabstände (Zeilenhöhe 1,5, Absatzabstand 2-fach, Zeichenabstand 0,12 em, Wortabstand 0,16 em) lassen keinen Inhalt und keine Funktion verlieren. | Betrifft auch Verzeichniseinträge, Buttons, Kommentare und Änderungsvergleiche. |
| 17 | N/P | Alle Funktionen sind per Tastatur erreichbar; der Fokus ist sichtbar und wird nicht vollständig verdeckt. | Nachvollziehbarer Fokusverlauf beim Öffnen und Schließen zusätzlicher Bereiche. |
| 18 | N/H | Bedienziele erfüllen mindestens WCAG 2.5.8; für häufige Beteiligungsaktionen 44 × 44 CSS-Pixel. | Die 44 Pixel sind ein bewusst höheres Projektziel. |
| 19 | N/P/H | Handlungen geben verständliche Rückmeldung, Fehler sind korrigierbar, eingegebener Text bleibt bei korrigierbaren Fehlern erhalten. | Statusmeldungen sind auch assistiver Technik zugänglich. |
| 20 | P + Vorgabe | Die Abnahme prüft vollständige Beteiligungsabläufe mit beiden Zielgruppen, realistischen langen Texten und manuellen wie automatisierten Barrierefreiheitstests. | Lesen, Wiederfinden, Unterstützen, Kommentieren und Änderungsverfahren, einschließlich Tastatur, Screenreader, Vergrößerung und unterschiedlicher Instanzgestaltung. |

## Stand des Mockups gegen den Katalog

| Urteil | Kriterien |
| --- | --- |
| Erfüllt | 2, 4, 6, 7, 9, 10, 18 |
| Erfüllt nach Korrektur | 3 (Inhaltsverzeichnis klappt bei offenem Panel ein), 14 (Kontraste berechnet, Auswahlrahmen verstärkt) |
| Teilweise | 5, 8, 12, 13, 17, 19 |
| Offen, zur Entscheidung | 11 (Wörter an den Absatzsymbolen, Entscheidung Nr. 2 der Bauanleitung) |
| Im Mockup nicht prüfbar | 1, 15, 16, 20 |

Abweichung im Begriff: Der Katalog spricht von „Unterstützen", das Modul verwendet „Stimme zu" (Entscheidung Nr. 3).
