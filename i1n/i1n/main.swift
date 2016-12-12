#!/usr/bin/swift

import Foundation

//MARK: Infrastructure

extension String {
    func lastIndex(of target: String) -> Int? {
        if let range = self.range(of: target, options: .backwards) {
            return characters.distance(from: startIndex, to: range.lowerBound)
        } else {
            return nil
        }
    }
}

struct LocalizationEntry {
    var path : String
    var key : String
}

class PropertyName {
    static func propertyName(parts : [String]) -> String {
        var propertyName = ""
        propertyName = parts[0]
        if (parts.count > 1) {
            for index in 1...parts.count-1 {
                propertyName += capitalizeFirstCharacter(string: parts[index])
            }
        }
        return propertyName
    }
    
    private static func capitalizeFirstCharacter(string : String) -> String {
        let capitalized = String(string[string.startIndex]).uppercased()

        return string.replacingCharacters(in:string.startIndex..<string.startIndex, with: capitalized)
    }
}

struct LanguageReport {
    var language : String
    var file : String
    var missingKeys : [String]
}

class Report {
    var allLanguages : [LanguageReport] = []
    
    init() {        
    }
    
    func missingEntriesCount() -> Int {
        var count = 0
        for language in allLanguages {
            count += language.missingKeys.count
        }
        return count
    }
}

func findLocalizationFiles(atPath path : String) -> [String] {
    let fileManager = FileManager.default
    let enumerator = fileManager.enumerator(atPath: path)
    var localizationFiles : [String] = []
    while let element = enumerator?.nextObject() as? String  {
        if element.hasSuffix(".strings") {
            localizationFiles.append(path + "/" + element)
        }
    }
    return localizationFiles
}

func parseLocalizationFile(_ file : String) -> [LocalizationEntry] {
    var localizationEntries : [LocalizationEntry] = []
    let content : String
    do {
        content = try String(contentsOfFile: file)
        let lines = content.components(separatedBy: "\n")
        for var line in lines {
            line = line.trimmingCharacters(in: NSCharacterSet.whitespaces)
            guard line.hasPrefix("\"") else {
                continue
            }
            line.remove(at: line.startIndex)
            if let index = line.characters.index(of: "\"") {
                let key = line.substring(to: index)
                localizationEntries.append(LocalizationEntry(path: file, key: key))
            }
        }
    } catch {
        content = ""
    }
    return localizationEntries
}

func searchForMissingKeys(inFile file : String, englishEntries : [LocalizationEntry]) -> LanguageReport {
    var report = LanguageReport(language: "", file: file, missingKeys: [])
    let nonEnglisEnries = parseLocalizationFile(file)
    for englishEntry in englishEntries {
        let language = localizationFileLanguage(file)
        report.language = language
        if !nonEnglisEnries.contains(where: { $0.key == englishEntry.key }) {
            report.missingKeys.append(englishEntry.key)
            print("\tMissing \(englishEntry.key) for \(language) in \(file)")
        }
    }
    return report
}

func localizationFileLanguage(_ file : String) -> String {
    var localizationCode = file.substring(to: file.index(file.endIndex, offsetBy: -(".lproj/Localizable.strings".characters.count)))
    let lastIndexOfDash = localizationCode.lastIndex(of: "/")
    guard lastIndexOfDash != nil else {
        return ""
    }
    localizationCode = localizationCode.substring(from: file.index(file.startIndex, offsetBy: lastIndexOfDash!+1))
    let codeToLanguage = [
        "en" : "English",
        "en-GB" : "English (British)",
        "en-AU" : "English (Australian)",
        "en-CA" : "English (Canadian)",
        "en-IN" : "English (Indian)",
        "fr" : "French",
        "fr-CA" : "French (Canadian)",
        "es" : "Spanish",
        "es-MX" : "Spanish (Mexico)",
        "pt" : "Portuguese",
        "pt-BR" : "Portuguese (Brazil)",
        "it" : "Italian",
        "de" : "German",
        "zh-Hans" : "Chinese (Simplified)",
        "zh-Hant" : "Chinese (Traditional)",
        "zh-HK" : "Chinese (Hong Kong)",
        "nl" : "Dutch",
        "ja" : "Japanese",
        "ko" : "Korean",
        "vi" : "Vietnamese",
        "ru" : "Russian",
        "sv" : "Swedish",
        "da" : "Danish",
        "fi" : "Finnish",
        "nb" : "Norwegian (Bokmal)",
        "tr" : "Turkish",
        "el" : "Greek",
        "id" : "Indonesian",
        "ms" : "Malay",
        "th" : "Thai",
        "hi" : "Hindi",
        "hu" : "Hungarian",
        "pl" : "Polish",
        "cs" : "Czech",
        "sk" : "Slovak",
        "uk" : "Ukrainian",
        "hr" : "Croatian",
        "ca" : "Catalan",
        "ro" : "Romanian",
        "he" : "Hebrew",
        "ar" : "Arabic"
    ]
    return codeToLanguage[localizationCode]!
}

func generateHtmlReport(_ report : Report) {
    let output = ""
    let reportFile = FileManager.default.currentDirectoryPath.appending("/report.xml")
    let reportFileUrl = URL(fileURLWithPath: reportFile)
    do {
        try output.write(to: reportFileUrl, atomically: true, encoding: String.Encoding.utf8)
    } catch {
        print("Failed to write report to \(reportFileUrl)")
    }
}


//MARK: Main

//Scan for all localization files
print("Searching for english localization file...")
let files = findLocalizationFiles(atPath: FileManager.default.currentDirectoryPath)

//Mark the english localization files
var englishLocalizationFile = ""
for file in files {
    if file.hasSuffix("en.lproj/Localizable.strings") {
        englishLocalizationFile = file
    }
}
if englishLocalizationFile == "" {
    print("\tEnglish localization file not found.")
    exit(1)
}


print("\tEnglish localization file found:\n\t \(englishLocalizationFile)")

print("Parsing all keys in the english localization file...")
let englishEntries = parseLocalizationFile(englishLocalizationFile)
print("\tDone")

print("Search for missing keys in non-english localization files...")

var report = Report()
for file in files {
    //Check for non-english localization file
    guard file != englishLocalizationFile else {
        continue
    }
    let languageReport = searchForMissingKeys(inFile: file, englishEntries: englishEntries)
    report.allLanguages.append(languageReport)
}

generateHtmlReport(report)

let missingEntriesCount = report.missingEntriesCount()
if missingEntriesCount == 0 {
    print("Finished, no missing localization entries.")
} else {
    print("Finished, missing \(missingEntriesCount) entries")
}










