# Convert Distribution Lists to Microsoft 365 Groups

This repository contains a PowerShell script that automates the conversion of distribution lists to Microsoft 365 groups, including all the delegates as members while keeping the same owner. Additionally, the script allows for changing the default owner by specifying the original owner and the new owner's email address.

## Prerequisites

- Exchange Online Management Module
- Multi-Factor Authentication (MFA) support.

To install the Exchange Online Management Module, run:

``` 
Install-Module -Name ExchangeOnlineManagement
```

## Usage

To use the script, you have various parameters at your disposal:

- `DLList`: Enter a comma-separated list of distribution list email addresses to convert.
- `All`: Convert all eligible distribution lists.
- `Test`: Perform a dry run of the conversion process without actually converting the distribution lists.
- `ListAll`: List all distribution lists, showing both eligible and non-eligible ones.
- `OriginalOwner`: Enter the email address of the original owner to be replaced.
- `NewOwner`: Enter the email address of the new owner.
- `Help`: Display help information.

### Examples

1. Convert specific distribution lists:

``` 
.\ConvertDLto365Group.ps1 -DLList "distlist1@example.com, distlist2@example.com"

```


2. Convert all eligible distribution lists:
```
.\ConvertDLto365Group.ps1 -All
```

3. List all distribution lists and their eligibility for conversion:
```
.\ConvertDLto365Group.ps1 -ListAll
```


## Logging

The script writes log entries to a file named `365ConversionLog_<yyyyMMdd>.txt` in the `C:\logs` directory on Windows or `/var/log` on Unix systems.

## Notes

- The script requires that you have the Exchange Online Management Module installed and MFA support.
- Ensure you have the proper permissions and credentials for the Exchange Online environment.
- The script is designed to provide options to either convert specific distribution lists, all eligible lists or perform a dry run for testing purposes.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

Please check the repository for licensing details.

## Disclaimer

This script is provided as-is, without warranties or guarantees of any kind. Use it at your own risk. Always test scripts in a safe environment before using them in production.
