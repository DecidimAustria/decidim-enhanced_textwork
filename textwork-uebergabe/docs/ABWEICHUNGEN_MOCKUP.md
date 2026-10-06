# Mockup und Bauanleitung

Das Mockup entspricht den Entscheidungen der Bauanleitung. Es ist verbindlich für Aufbau, Reihenfolge, Wortlaut und Verhalten. Diese Datei nennt, wo es bewusst vereinfacht ist und was es nicht zeigt. In allen diesen Punkten gilt die Bauanleitung.

## Vereinfacht dargestellt

| Thema | Im Mockup | Es gilt (Bauanleitung) |
| --- | --- | --- |
| Farben, Schrift, Abstände | Eigene Annäherung an Decidim | Tailwind-Klassen und Komponenten aus Decidim 0.32 (Regel 7) |
| Listen | Als Zeilen mit vorangestelltem Strich, auch in der Leseansicht | In der Leseansicht als echte Liste dargestellt; nur im Eingabefeld als Zeilen mit Strich (3.1, 5.4) |
| Fett, kursiv, Links | Kommen im Beispieltext nicht vor | Teil der Markdown-Teilmenge (3.1) |
| Vergleich bei Listen | Wortvergleich über den ganzen Text, Zeilenumbruch als eigenes Zeichen | Zuerst zeilenweise, dann wortweise (5.4) |
| Kommentare | Eigene Darstellung mit Daumen hoch, Daumen runter und „Antworten" | Kommentar-Ansicht des Kerns unverändert, mit Zustimmung und Ablehnung (Entscheidung 4) |
| Bearbeiten eines eigenen Vorschlags | Dasselbe Formular wie beim neuen Vorschlag, Bestätigung „eingereicht" | Eigener Command `UpdateSuggestion`, Bestätigung „aktualisiert" (3.6, Übersetzungsdatei) |
| Zurückziehen | Sofort, ohne Rückfrage | Mit Bestätigungsdialog nach Decidim-Praxis |
| Vorschlag zu früherer Fassung | Markierung im Text zeigt den Vergleich zur alten Fassung, Etikett nennt „zu Fassung 1" | Wie im Mockup; zusätzlich Warnung und anpassbarer Text bei der Annahme im Admin-Bereich (3.6) |
| Angemeldet | Desktop und mobil zeigen den angemeldeten Zustand („Testperson") | Nicht angemeldet: Anmelde-Dialog von Decidim bei jeder Aktion, die ein Konto braucht (5.7) |

## Nicht dargestellt

Für diese Teile gibt es im Mockup keine Ansicht. Sie ergeben sich aus der Bauanleitung und der üblichen Praxis von Decidim:

- Übersetzte Ansichten und der Vermerk „Übersetzung wird erstellt" (3.7, 5.4)
- Alle Ansichten im Admin-Bereich: Dokumente, Import, offene Vorschläge, Annehmen, Ablehnen, redaktionelle Änderung
- Versionsverlauf (eigene Seite nach Kern-Standard, Entscheidung 26)
- „Stimme zu" und „Folgen" am Dokumenttitel bei Texten ohne Überschriften (3.2)
- Gesperrte Aktionen je Phase (3.9)
- Einfügen, Entfernen und Umstellen von Absätzen nach der Veröffentlichung und der Änderungsverlauf des Dokuments (3.4.1, 3.6)
- Hinweise „Dieser Absatz wurde entfernt." und „Dieser Änderungsvorschlag ist nicht verfügbar."
- Fehlermeldungen und Bestätigungsdialoge außer „Entwurf verwerfen?"
- Benachrichtigungen (3.8)

## Nur Attrappe

Sichtbar, aber ohne Funktion: „Kommentieren", „Antworten", „Folgen", „Melden" in der Detailansicht eines Vorschlags und die Einträge im Drei-Punkte-Menü.

## Erfundene Inhalte

Namen in eckigen Klammern, Daten als „[Datum]", die Änderungsvorschläge zu Absatz 1.2, die abgeschlossenen Beispiele, der Listen-Absatz 2.2 und alle Zahlen der Zustimmungen sind Beispieldaten.
