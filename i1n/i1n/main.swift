#!/usr/bin/swift

import Foundation

let version = "0.0.1"

//MARK: Infrastructure
extension String {
    func lastIndex(of target: String) -> Int? {
        if let range = self.range(of: target, options: .backwards) {
            return characters.distance(from: startIndex, to: range.lowerBound)
        } else {
            return nil
        }
    }
    
    func appendTo(path : String) -> Bool {
        guard FileManager.default.fileExists(atPath: path) else {
            return false
        }
        let pathUrl = URL(fileURLWithPath: path)
        let data = self.data(using: String.Encoding.utf8)
        guard data != nil else {
            return false
        }
        do {
            let fileHandle = try FileHandle(forWritingTo: pathUrl)
            fileHandle.seekToEndOfFile()
            fileHandle.write(data!)
            fileHandle.closeFile()
        } catch {
            do {
                try data!.write(to: pathUrl, options: .atomic)
            } catch {
                return false
            }
            return false
        }
        return true
    }
}

struct LocalizationEntry {
    var path : String
    var key : String
    var value : String
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

class ArgumentsParser {
    var printUsage : Bool = false
    var printVersion : Bool = false
    var addMissingEntries : Bool = false
    
    init(arguments : [String]) {
        parse(arguments)
    }
    
    func parse(_ arguments : [String]) {
        if (arguments.contains("--help") || arguments.contains("-h")) {
            printUsage = true
        }
        if (arguments.contains("--version") || arguments.contains("-v")) {
            printVersion = true
        }
        if (arguments.contains("-a")) {
            addMissingEntries = true
        }
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
                let key = localizationKeyFromLine(line)
                if let key = key {
                    let lastIndex = line.lastIndex(of: "\"")
                    let range =  line.characters.index(index, offsetBy: 5)..<line.characters.index(line.startIndex, offsetBy: lastIndex!)
                    let value = line.substring(with: range)
                    localizationEntries.append(LocalizationEntry(path: file, key: key, value: value))
                } else {
                    print("Failed to parse line: \(line)")
                }
            }
        }
    } catch {
        content = ""
    }
    return localizationEntries
}

func localizationKeyFromLine(_ line : String) -> String? {
    var previousCharacter : Character = "\0"
    var endOfKeyIndex : String.CharacterView.Index? = nil
    for index in line.characters.indices {
        if line[index] == "\"" && previousCharacter != "\\" {
            //End of key
            endOfKeyIndex = index
            break
        }
        previousCharacter = line[index]
    }
    guard endOfKeyIndex != nil else {
        return nil
    }
    return line.substring(to: endOfKeyIndex!)
}


func searchForMissingKeys(inFile file : String, englishEntries : [LocalizationEntry], addMissingEntries : Bool) -> LanguageReport {
    var report = LanguageReport(language: "", file: file, missingKeys: [])
    guard let language = localizationFileLanguage(file) else {
        print("Unknown language for file: \(file)")
        print("Skipping")
        return report
    }
    let nonEnglishEnries = parseLocalizationFile(file)
    for englishEntry in englishEntries {
        report.language = language
        if !nonEnglishEnries.contains(where: { $0.key == englishEntry.key }) {
            if shouldIgnoreSingularKeyFor(language) && hasSingularSuffix(englishEntry.key) {
                if nonEnglishEnries.contains(where: { $0.key == removeSingularSuffix(englishEntry.key) + "##{other}" }) {
                    continue
                }
            }
            report.missingKeys.append(englishEntry.key)
            if addMissingEntries {
                let defaultValue = "\n\"\(englishEntry.key)\" = \"\(englishEntry.value)\";"
                let writeResult = defaultValue.appendTo(path: file)
                if writeResult {
                    print("Added \(englishEntry.key) to \(file)")
                } else {
                    print("Failed to add \(englishEntry.key) to \(file)")
                }
            }
        }
    }
    return report
}

func shouldIgnoreSingularKeyFor(_ language: String) -> Bool {
    switch language {
    case "Japanese", "Korean","Thai","Chinese (Simplified)","Chinese (Traditional)":
        return true
    default:
        return false
    }
}

func hasSingularSuffix(_ key: String) -> Bool {
    return key.hasSuffix("##{one}")
}

func removeSingularSuffix(_ key: String) -> String {
    let index = key.index(key.endIndex, offsetBy: -("##{one}".characters.count))
    return key.substring(to: index)
}

func localizationFileLanguage(_ file : String) -> String? {
    var localizationCode = file.substring(to: file.index(file.endIndex, offsetBy: -(".lproj/Localizable.strings".characters.count)))
    let lastIndexOfDash = localizationCode.lastIndex(of: "/")
    guard lastIndexOfDash != nil else {
        return ""
    }
    localizationCode = localizationCode.substring(from: file.index(file.startIndex, offsetBy: lastIndexOfDash!+1))
    if localizationCode == "Base" {
        return localizationCode
    }
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
    if let language = codeToLanguage[localizationCode] {
        return language
    }
    return localizationCode
}

func generateHtmlReport(_ report : Report) {
    var output = "<!DOCTYPE html>"
    output += "<html>"
    output += "<head>"
    output += "<title>Localization Report</title>"
    output += "<style>body{width:800px;margin:40px auto;font-family:'trebuchet MS','Lucida sans',Arial;font-size:14px;color:#444}table{*border-collapse:collapse;border-spacing:0;width:100%}.bordered{border:solid #ccc 1px;-moz-border-radius:6px;-webkit-border-radius:6px;border-radius:6px;-webkit-box-shadow:0 1px 1px #ccc;-moz-box-shadow:0 1px 1px #ccc;box-shadow:0 1px 1px #ccc}.bordered tr:hover{background:#fbf8e9;-o-transition:all .1s ease-in-out;-webkit-transition:all .1s ease-in-out;-moz-transition:all .1s ease-in-out;-ms-transition:all .1s ease-in-out;transition:all .1s ease-in-out}.bordered td,.bordered th{border-left:1px solid #ccc;border-top:1px solid #ccc;padding:10px;text-align:left}.bordered th{background-color:#dce9f9;background-image:-webkit-gradient(linear,left top,left bottom,from(#ebf3fc),to(#dce9f9));background-image:-webkit-linear-gradient(top,#ebf3fc,#dce9f9);background-image:-moz-linear-gradient(top,#ebf3fc,#dce9f9);background-image:-ms-linear-gradient(top,#ebf3fc,#dce9f9);background-image:-o-linear-gradient(top,#ebf3fc,#dce9f9);background-image:linear-gradient(top,#ebf3fc,#dce9f9);-webkit-box-shadow:0 1px 0 rgba(255,255,255,.8) inset;-moz-box-shadow:0 1px 0 rgba(255,255,255,.8) inset;box-shadow:0 1px 0 rgba(255,255,255,.8) inset;border-top:0;text-shadow:0 1px 0 rgba(255,255,255,.5)}.bordered td:first-child,.bordered th:first-child{border-left:none}.bordered th:first-child{-moz-border-radius:6px 0 0 0;-webkit-border-radius:6px 0 0 0;border-radius:6px 0 0 0}.bordered th:last-child{-moz-border-radius:0 6px 0 0;-webkit-border-radius:0 6px 0 0;border-radius:0 6px 0 0}.bordered th:only-child{-moz-border-radius:6px 6px 0 0;-webkit-border-radius:6px 6px 0 0;border-radius:6px 6px 0 0}.bordered tr:last-child td:first-child{-moz-border-radius:0 0 0 6px;-webkit-border-radius:0 0 0 6px;border-radius:0 0 0 6px}.bordered tr:last-child td:last-child{-moz-border-radius:0 0 6px 0;-webkit-border-radius:0 0 6px 0;border-radius:0 0 6px 0}.zebra td,.zebra th{padding:10px;border-bottom:1px solid #f2f2f2}.zebra tbody tr:nth-child(even){background:#f5f5f5;-webkit-box-shadow:0 1px 0 rgba(255,255,255,.8) inset;-moz-box-shadow:0 1px 0 rgba(255,255,255,.8) inset;box-shadow:0 1px 0 rgba(255,255,255,.8) inset}.zebra th{text-align:left;text-shadow:0 1px 0 rgba(255,255,255,.5);border-bottom:1px solid #ccc;background-color:#eee;background-image:-webkit-gradient(linear,left top,left bottom,from(#f5f5f5),to(#eee));background-image:-webkit-linear-gradient(top,#f5f5f5,#eee);background-image:-moz-linear-gradient(top,#f5f5f5,#eee);background-image:-ms-linear-gradient(top,#f5f5f5,#eee);background-image:-o-linear-gradient(top,#f5f5f5,#eee);background-image:linear-gradient(top,#f5f5f5,#eee)}.zebra th:first-child{-moz-border-radius:6px 0 0 0;-webkit-border-radius:6px 0 0 0;border-radius:6px 0 0 0}.zebra th:last-child{-moz-border-radius:0 6px 0 0;-webkit-border-radius:0 6px 0 0;border-radius:0 6px 0 0}.zebra th:only-child{-moz-border-radius:6px 6px 0 0;-webkit-border-radius:6px 6px 0 0;border-radius:6px 6px 0 0}.zebra tfoot td{border-bottom:0;border-top:1px solid #fff;background-color:#f1f1f1}.zebra tfoot td:first-child{-moz-border-radius:0 0 0 6px;-webkit-border-radius:0 0 0 6px;border-radius:0 0 0 6px}.zebra tfoot td:last-child{-moz-border-radius:0 0 6px 0;-webkit-border-radius:0 0 6px 0;border-radius:0 0 6px 0}.zebra tfoot td:only-child{-moz-border-radius:0 0 6px 6px;-webkit-border-radius:0 0 6px 6px border-radius:0 0 6px 6px}</style>"
    output += "</head>"
    output += "<body>"
    for language in report.allLanguages {
        if language.missingKeys.count == 0 {
            continue
        }
        output += "<h2>\(language.language)</h2>"
        output += "<h3>\(language.file)</h3>"
        output += "<table class=zebra><tr><th>Key</th></tr>"
        for key in language.missingKeys {
            output += "<tr><td>\(key)</td></tr>"
        }
        output += "<tr><th>Total: \(language.missingKeys.count)</th></tr>"
        output += "</table>"
    }
    let languagesMissingCount = report.allLanguages.map { $0.missingKeys.count }
    let totalCount = languagesMissingCount.reduce(0, { $0 + $1 })
    if (totalCount == 0) {
        output += "<h2>No misssing keys</h2>"
    }
    output += "<br /><br /><p>Thanks to <a href=http://twitter.com/catalinred>Catalin Rosu</a> for the HTML template!</p>"
    output += "</body>"
    output += "</html>"
    
    let reportFile = FileManager.default.currentDirectoryPath.appending("/report.html")
    let reportFileUrl = URL(fileURLWithPath: reportFile)
    do {
        try output.write(to: reportFileUrl, atomically: true, encoding: String.Encoding.utf8)
    } catch {
        print("Failed to write report to \(reportFileUrl)")
    }
}

func printUsage() {
    let options : [[String]] = [["-a", "Add missing entries with their english value"]]
    print("Usage:")
    print("\ti1n [options]")
    print("Options:")
    for option in options {
        print("\t\(option[0]) \t\t\t \(option[1])")
    }
}

func printVersion() {
    print("\(version)")
}


//MARK: Main

//Scan for all localization files
let argumentsParser = ArgumentsParser(arguments: CommandLine.arguments)
if argumentsParser.printUsage {
    printUsage()
    exit(EXIT_SUCCESS)
}
if argumentsParser.printVersion {
    printVersion()
    exit(EXIT_SUCCESS)
}


print("Searching for english localization file...")
let files = findLocalizationFiles(atPath: FileManager.default.currentDirectoryPath)

//Mark the english localization files
var englishLocalizationFile = ""
for file in files {
    if file.hasSuffix("en.lproj/Localizable.strings") {
        englishLocalizationFile = file
        break
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

print("Searching for missing keys in non-english localization files...")

var report = Report()
for file in files {
    //Check for non-english localization file
    guard file != englishLocalizationFile else {
        continue
    }
    let languageReport = searchForMissingKeys(inFile: file, englishEntries: englishEntries, addMissingEntries: argumentsParser.addMissingEntries)
    report.allLanguages.append(languageReport)
}

generateHtmlReport(report)

let missingEntriesCount = report.missingEntriesCount()
if missingEntriesCount == 0 {
    print("Finished, no missing localization entries.")
    exit(EXIT_SUCCESS)
} else {
    print("Finished, missing \(missingEntriesCount) entries")
    exit(EXIT_FAILURE)
}










