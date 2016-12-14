# i1n - The safe way to heavenly localization 
i1n will scan your Xcode project and compare the keys in your english localization file
to all other available languages.

The result is a report with all keys available in for english but missing for other languages.


**This project is still in early stages.**

## Requirements 
This is a swift script file written in Swift 3, and assume you have Xcode 8 installed.

## Installation
Add execution permissions to the *main.swift*:

`chmod +x main.swift`

Copy & Rename the *main.swift* to folder in your PATH, for example:

`sudo cp main.swift /usr/local/bin/i1n`

## Execution
Run the **i1n** script from the root of your project (assuming i1n exists at /usr/local/bin/i1n):

`i1n`

Sample output:

![alt-text][execution]

##Demo 
You can run **i1n** on the Demo project to see it in action.

![alt text][report]

## Adding the missing keys with default value
Running **i1n -a** will add the missing keys to the localization files with their english values.

![alt text][missing-base]

![alt-text-][missing-spanish]


# Thanks
To <a href=http://twitter.com/catalinred>Catalin Rosu</a> for the HTML template!

[execution]: https://raw.githubusercontent.com/idomizrachi/i1n/master/Demo/Sample-Execution.png "Execution"
[report]: https://raw.githubusercontent.com/idomizrachi/i1n/master/Demo/Demo-Report.png "Report"
[missing-base]: https://raw.githubusercontent.com/idomizrachi/i1n/master/Demo/Base-Missing-Keys.png "Missing Base"
[missing-spanish]: https://raw.githubusercontent.com/idomizrachi/i1n/master/Demo/Spanish-Missing-Keys.png
