# Copyright (c) 2002-2018 "Neo4j,"
# Neo4j Sweden AB [http://neo4j.com]
#
# This file is part of Neo4j.
#
# Neo4j is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


<#
.SYNOPSIS
Invokes various Neo4j Utilities

.DESCRIPTION
Invokes various Neo4j Utilities.  This is a generic utility function called by the external functions e.g. Shell, Import

.PARAMETER Command
A string of the command to run.

.PARAMETER CommandArgs
Command line arguments to pass to the utility

.OUTPUTS
System.Int32
0 = Success
non-zero = an error occured

.NOTES
Only supported on version 3.x Neo4j Community and Enterprise Edition databases

.NOTES
This function is private to the powershell module

#>
function Invoke-Neo4jUtility
{
  [CmdletBinding(SupportsShouldProcess = $false,ConfirmImpact = 'Low')]
  param(
    [Parameter(Mandatory = $false,ValueFromPipeline = $false,Position = 0)]
    [string]$Command = ''

    ,[Parameter(Mandatory = $false,ValueFromRemainingArguments = $true)]
    [object[]]$CommandArgs = @()
  )

  begin
  {
  }

  process
  {
    # Determine the Neo4j Home Directory.  Uses the NEO4J_HOME environment variable or a parent directory of this script
    $Neo4jHome = Get-Neo4jEnv 'NEO4J_HOME'
    if (($Neo4jHome -eq $null) -or (-not (Test-Path -Path $Neo4jHome))) {
      $Neo4jHome = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    }
    if ($Neo4jHome -eq $null) { throw "Could not determine the Neo4j home Directory.  Set the NEO4J_HOME environment variable and retry" }
    Write-Verbose "Neo4j Root is '$Neo4jHome'"

    $thisServer = Get-Neo4jServer -Neo4jHome $Neo4jHome -ErrorAction Stop
    if ($thisServer -eq $null) { throw "Unable to determine the Neo4j Server installation information" }
    Write-Verbose "Neo4j Server Type is '$($thisServer.ServerType)'"
    Write-Verbose "Neo4j Version is '$($thisServer.ServerVersion)'"
    Write-Verbose "Neo4j Database Mode is '$($thisServer.DatabaseMode)'"

    $GetJavaParams = @{}
    switch ($Command.Trim().ToLower())
    {
      "admintool" {
        Write-Verbose "Admintool command specified"
        $GetJavaParams = @{
          StartingClass = 'org.neo4j.commandline.admin.AdminTool';
        }
        break
      }
      "import" {
        Write-Verbose "Import command specified"
        $GetJavaParams = @{
          StartingClass = 'org.neo4j.tooling.ImportTool';
        }
        break
      }
      "backup" {
        Write-Verbose "Backup command specified"
        if ($thisServer.ServerType -ne 'Enterprise')
        {
          throw "Neo4j Server type $($thisServer.ServerType) does not support online backup"
        }
        $GetJavaParams = @{
          StartingClass = 'org.neo4j.backup.BackupTool';
        }
        break
      }
      default {
        Write-Host "Unknown utility $Command"
        return 255
      }
    }

    # Generate the required Java invocation
    $JavaCMD = Get-Java -Neo4jServer $thisServer -ForUtility @GetJavaParams
    if ($JavaCMD -eq $null) { throw 'Unable to locate Java' }

    $ShellArgs = $JavaCMD.args
    if ($ShellArgs -eq $null) { $ShellArgs = @() }
    # Add unbounded command line arguments
    $ShellArgs += $CommandArgs

    Write-Verbose "Starting neo4j utility using command line $($JavaCMD.java) $ShellArgs"
    $result = (Start-Process -FilePath $JavaCMD.java -ArgumentList $ShellArgs -Wait -NoNewWindow -Passthru)
    return $result.exitCode
  }

  end
  {
  }
}

# SIG # Begin signature block
# MIId1gYJKoZIhvcNAQcCoIIdxzCCHcMCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBDG4B6+sfR0SdD
# H2czcLlZq0QIWdq9tWO6ssJICyv9QaCCGEYwggPFMIICraADAgECAgEAMA0GCSqG
# SIb3DQEBCwUAMIGDMQswCQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTETMBEG
# A1UEBxMKU2NvdHRzZGFsZTEaMBgGA1UEChMRR29EYWRkeS5jb20sIEluYy4xMTAv
# BgNVBAMTKEdvIERhZGR5IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzIw
# HhcNMDkwOTAxMDAwMDAwWhcNMzcxMjMxMjM1OTU5WjCBgzELMAkGA1UEBhMCVVMx
# EDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAYBgNVBAoT
# EUdvRGFkZHkuY29tLCBJbmMuMTEwLwYDVQQDEyhHbyBEYWRkeSBSb290IENlcnRp
# ZmljYXRlIEF1dGhvcml0eSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEAv3FiCPH6WTT3G8kYo/eASVjpIoMTpsUgQwE7hPHmhUmfJ+r2hBtOoLTb
# cJjHMgGxBT4HTu70+k8vWTAi56sZVmvigAf88xZ1gDlRe+X5NbZ0TqmNghPktj+p
# A4P6or6KFWp/3gvDthkUBcrqw6gElDtGfDIN8wBmIsiNaW02jBEYt9OyHGC0OPoC
# jM7T3UYH3go+6118yHz7sCtTpJJiaVElBWEaRIGMLKlDliPfrDqBmg4pxRyp6V0e
# tp6eMAo5zvGIgPtLXcwy7IViQyU0AlYnAZG0O3AqP26x6JyIAX2f1PnbU21gnb8s
# 51iruF9G/M7EGwM8CetJMVxpRrPgRwIDAQABo0IwQDAPBgNVHRMBAf8EBTADAQH/
# MA4GA1UdDwEB/wQEAwIBBjAdBgNVHQ4EFgQUOpqFBxBnKLbv9r0FQW4gwZTaD94w
# DQYJKoZIhvcNAQELBQADggEBAJnbXXnV+ZdZZwNh8X47BjF1LaEgjk9lh7T3ppy8
# 2Okv0Nta7s90jHO0OELaBXv4AnW4/aWx1672194Ty1MQfopG0Zf6ty4rEauQsCeA
# +eifWuk3n6vk32yzhRedPdkkT3mRNdZfBOuAg6uaAi21EPTYkMcEc0DtciWgqZ/s
# nqtoEplXxo8SOgmkvUT9BhU3wZvkMqPtOOjYZPMsfhT8Auqfzf8HaBfbIpA4LXqN
# 0VTxaeNfM8p6PXsK48p/Xznl4nW6xXYYM84s8C9Mrfex585PqMSbSlQGxX991QgP
# 4hz+fhe4rF721BayQwkMTfana7SZhGXKeoji4kS+XPfqHPUwggTQMIIDuKADAgEC
# AgEHMA0GCSqGSIb3DQEBCwUAMIGDMQswCQYDVQQGEwJVUzEQMA4GA1UECBMHQXJp
# em9uYTETMBEGA1UEBxMKU2NvdHRzZGFsZTEaMBgGA1UEChMRR29EYWRkeS5jb20s
# IEluYy4xMTAvBgNVBAMTKEdvIERhZGR5IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9y
# aXR5IC0gRzIwHhcNMTEwNTAzMDcwMDAwWhcNMzEwNTAzMDcwMDAwWjCBtDELMAkG
# A1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUx
# GjAYBgNVBAoTEUdvRGFkZHkuY29tLCBJbmMuMS0wKwYDVQQLEyRodHRwOi8vY2Vy
# dHMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeS8xMzAxBgNVBAMTKkdvIERhZGR5IFNl
# Y3VyZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBHMjCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBALngyxDUr3a91JNi6zBkuIEIbMME2WIXji//PmXPj85i
# 5jxSHNoWRUtVq3hrY4NikM4PaWyZyBoUi0zMRTPqiNyeo68r/oBhnXlXxM8u9D8w
# PF1H/JoWvMM3lkFRjhFLVPgovtCMvvAwOB7zsCb4Zkdjbd5xJkePOEdT0UYdtOPc
# AOpFrL28cdmqbwDb280wOnlPX0xH+B3vW8LEnWA7sbJDkdikM07qs9YnT60liqXG
# 9NXQpq50BWRXiLVEVdQtKjo++Li96TIKApRkxBY6UPFKrud5M68MIAd/6N8EOcJp
# AmxjUvp3wRvIdIfIuZMYUFQ1S2lOvDvTSS4f3MHSUvsCAwEAAaOCARowggEWMA8G
# A1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMB0GA1UdDgQWBBRAwr0njsw0
# gzCiM9f7bLPwtCyAzjAfBgNVHSMEGDAWgBQ6moUHEGcotu/2vQVBbiDBlNoP3jA0
# BggrBgEFBQcBAQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmdvZGFkZHku
# Y29tLzA1BgNVHR8ELjAsMCqgKKAmhiRodHRwOi8vY3JsLmdvZGFkZHkuY29tL2dk
# cm9vdC1nMi5jcmwwRgYDVR0gBD8wPTA7BgRVHSAAMDMwMQYIKwYBBQUHAgEWJWh0
# dHBzOi8vY2VydHMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeS8wDQYJKoZIhvcNAQEL
# BQADggEBAAh+bJMQyDi4lqmQS/+hX08E72w+nIgGyVCPpnP3VzEbvrzkL9v4utNb
# 4LTn5nliDgyi12pjczG19ahIpDsILaJdkNe0fCVPEVYwxLZEnXssneVe5u8MYaq/
# 5Cob7oSeuIN9wUPORKcTcA2RH/TIE62DYNnYcqhzJB61rCIOyheJYlhEG6uJJQEA
# D83EG2LbUbTTD1Eqm/S8c/x2zjakzdnYLOqum/UqspDRTXUYij+KQZAjfVtL/qQD
# WJtGssNgYIP4fVBBzsKhkMO77wIv0hVU7kQV2Qqup4oz7bEtdjYm3ATrn/dhHxXc
# h2/uRpYoraEmfQoJpy4Eo428+LwEMAEwggUAMIID6KADAgECAgEHMA0GCSqGSIb3
# DQEBCwUAMIGPMQswCQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTETMBEGA1UE
# BxMKU2NvdHRzZGFsZTElMCMGA1UEChMcU3RhcmZpZWxkIFRlY2hub2xvZ2llcywg
# SW5jLjEyMDAGA1UEAxMpU3RhcmZpZWxkIFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9y
# aXR5IC0gRzIwHhcNMTEwNTAzMDcwMDAwWhcNMzEwNTAzMDcwMDAwWjCBxjELMAkG
# A1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUx
# JTAjBgNVBAoTHFN0YXJmaWVsZCBUZWNobm9sb2dpZXMsIEluYy4xMzAxBgNVBAsT
# Kmh0dHA6Ly9jZXJ0cy5zdGFyZmllbGR0ZWNoLmNvbS9yZXBvc2l0b3J5LzE0MDIG
# A1UEAxMrU3RhcmZpZWxkIFNlY3VyZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBH
# MjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOWQZkvs+UZxqSCDvuls
# v0rJSGmBdU5tJPbLFxP4sHFZhHprK4WkNLUW5cvM6UFwLKQu1voyfeGo3pQQrDHB
# wNhq/1knq3bW/At0a7inrj/EVPS0MUTdk1aMpExem4nLJIOb4ld9t9gSH8mFbfTR
# gPFQm4eu1AsQBfsnuihtF+kO1k25OVUG/wokBX4vxh1ybNSLKYxXfdrZ62Ya00+n
# 339SxDDFpckOAsVTv3c4aAYkw2bIN34wHkVxIzX/kNgqnY3nsJJNPH8qCpPczRZG
# ZfdghIt2S5EncxSS4OrujxbqjQ4+dhe/fYmAgERD5y3gQwl12jborduJOvVdEo4j
# BIMCAwEAAaOCASwwggEoMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEG
# MB0GA1UdDgQWBBQlRYFoUCY4PTstLL7Natm2PbNmYzAfBgNVHSMEGDAWgBR8DDIf
# p9kwf8R9aKNiqKHOqwdbJzA6BggrBgEFBQcBAQQuMCwwKgYIKwYBBQUHMAGGHmh0
# dHA6Ly9vY3NwLnN0YXJmaWVsZHRlY2guY29tLzA7BgNVHR8ENDAyMDCgLqAshipo
# dHRwOi8vY3JsLnN0YXJmaWVsZHRlY2guY29tL3Nmcm9vdC1nMi5jcmwwTAYDVR0g
# BEUwQzBBBgRVHSAAMDkwNwYIKwYBBQUHAgEWK2h0dHBzOi8vY2VydHMuc3RhcmZp
# ZWxkdGVjaC5jb20vcmVwb3NpdG9yeS8wDQYJKoZIhvcNAQELBQADggEBAFZlyv7z
# Pwqok4sYx95DaRM0IL5OX3ioa5zbak1B28ET7NwxACJe9wCeDOA0ZTT5sTpOSMgS
# gYhcWz4IU3r3GmTfuFBhzFNRQClLwvSuOl/kyq0mzE5hQ+X9V6Y3cM5DK7CUw5Lp
# 4V+qEEm3aeTg0B9kpCvNH2+g+IQkGM55PamRv1QYE4mZVBENVcUmC3lPWhxu+WPb
# FICkB6v6sqW5iN2R/mU7pKN5volN4dCw9MgXDAqWFHwJt2zhwthV1BigqkFpcCSj
# ue/pWtw+65RK8LfeXw52+vv7aQNFQFDucgykEoaBzRPRTsQ8yk4N0ibxALe0pqLh
# bnqB/TCseh/HWXswggUhMIIECaADAgECAgkAhHYYKGL3whowDQYJKoZIhvcNAQEL
# BQAwgbQxCzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMwEQYDVQQHEwpT
# Y290dHNkYWxlMRowGAYDVQQKExFHb0RhZGR5LmNvbSwgSW5jLjEtMCsGA1UECxMk
# aHR0cDovL2NlcnRzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkvMTMwMQYDVQQDEypH
# byBEYWRkeSBTZWN1cmUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzIwHhcNMTcx
# MTA3MTkzNzAzWhcNMjAxMTA3MTkzNzAzWjBiMQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKQ2FsaWZvcm5pYTESMBAGA1UEBxMJU2FuIE1hdGVvMRQwEgYDVQQKEwtOZW80
# aiwgSW5jLjEUMBIGA1UEAxMLTmVvNGosIEluYy4wggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQDSoPiG1pU1Lvqo+aZsFTrUwaV1sDWVBtfWzSnDKB3bUJeC
# 7DhekXtt1FORi3PB4YAC/CSMGgwoBHuqgGuRaJbHjRlmYaZZdKVsgvmDwfEvv16j
# zoyUR8TMTTjCemIDAHwArEadkffpsgnFpQ6KG6+gag/39FXyM2rGmFaqSGkqjVRN
# u4zN5GQu8+CUvRuZO2zEuKdA4wv9ZlmWbV3bpCGIN3Zl4p39Fatz3KYNi4g8lFXh
# B8tJfBToRuqxLZpcuyrXG3PeLa6DNoYOJ3j49DJOEw8Wj9cnqvAaI3CNE2klZ7RS
# cE47YUh7rVpl/ykp9ohgZDtvhAA5RYI5KCnc+oXHAgMBAAGjggGFMIIBgTAMBgNV
# HRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMA4GA1UdDwEB/wQEAwIHgDA1
# BgNVHR8ELjAsMCqgKKAmhiRodHRwOi8vY3JsLmdvZGFkZHkuY29tL2dkaWcyczUt
# My5jcmwwXQYDVR0gBFYwVDBIBgtghkgBhv1tAQcXAjA5MDcGCCsGAQUFBwIBFito
# dHRwOi8vY2VydGlmaWNhdGVzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkvMAgGBmeB
# DAEEATB2BggrBgEFBQcBAQRqMGgwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmdv
# ZGFkZHkuY29tLzBABggrBgEFBQcwAoY0aHR0cDovL2NlcnRpZmljYXRlcy5nb2Rh
# ZGR5LmNvbS9yZXBvc2l0b3J5L2dkaWcyLmNydDAfBgNVHSMEGDAWgBRAwr0njsw0
# gzCiM9f7bLPwtCyAzjAdBgNVHQ4EFgQUvj4gytCNJMDPx3lWv0klX6YK41IwDQYJ
# KoZIhvcNAQELBQADggEBABzaEnMJczETlZUdZE36x84eQS2AmumczZzTMbZ4IhJw
# xF8vVz2+Q+0BcR5uwAXa+s167yqIZsxAub3nu8GzYAF7D7wHDC1H1JNkgfnZf1w2
# WWGL6jkbr5RGrLlU2xE8o03iuFglU4QQl9ouXXBLAsLo/q+pMrPs+EO+g3DwXGFt
# jAKzkrMzJD5Ia2kVSC2aAXrffwRqMpbKVxkf0TQadMGLa6dVybYH7qBfDZ+u8P2K
# Y0qQyQYY63WoVk7TIq1VkbmRXtcvm3/plWPUNTPPEy0DfnjndA2UByib6/iqdnSZ
# 7MYit31rmSsRAS3Wil/qqOGlVfYrSm2s64ryPMOacAkwggV8MIIEZKADAgECAghX
# 62vcgKuJTDANBgkqhkiG9w0BAQsFADCBxjELMAkGA1UEBhMCVVMxEDAOBgNVBAgT
# B0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxJTAjBgNVBAoTHFN0YXJmaWVs
# ZCBUZWNobm9sb2dpZXMsIEluYy4xMzAxBgNVBAsTKmh0dHA6Ly9jZXJ0cy5zdGFy
# ZmllbGR0ZWNoLmNvbS9yZXBvc2l0b3J5LzE0MDIGA1UEAxMrU3RhcmZpZWxkIFNl
# Y3VyZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBHMjAeFw0xOTA0MTUwNzAwMDBa
# Fw0yNDA0MTUwNzAwMDBaMIGHMQswCQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9u
# YTETMBEGA1UEBxMKU2NvdHRzZGFsZTEkMCIGA1UEChMbU3RhcmZpZWxkIFRlY2hu
# b2xvZ2llcywgTExDMSswKQYDVQQDEyJTdGFyZmllbGQgVGltZXN0YW1wIEF1dGhv
# cml0eSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzq8g420K
# 52oSzwX8q/EV5sVYhdhJzrc5/FQbiQOrax0PZYMoBKenJWo9sRQkwqkrxoTLzozz
# PqU/LG2H5knkw625cSMHB74FGHtPHjEju4tfnQFDI+XPzRGhvSPMrzPvg5zGGVT/
# Fku5z+AjU6LPPNFWR6vxVsz1Zq0y6cSLL0iJojP01SR6VtfNpzDMCu7p8OtpttH/
# GG/ohj3DMurv0NCrerzojzmWEr5oG8n2qtVAh2F/KmbzNmQ2wHNzGVFGm9YB1iVd
# G9M+V7zAs3HYbnSJKFi+k14UFgEYaiVnhxRCS+KREy8nEPaF6UII16Fxm3gJhJhO
# u3z25YPkk74PYQIDAQABo4IBqTCCAaUwDAYDVR0TAQH/BAIwADAOBgNVHQ8BAf8E
# BAMCBsAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwHQYDVR0OBBYEFHqrqS4tyGzj
# JXj2RtbFmwi6fyrvMB8GA1UdIwQYMBaAFCVFgWhQJjg9Oy0svs1q2bY9s2ZjMIGE
# BggrBgEFBQcBAQR4MHYwKgYIKwYBBQUHMAGGHmh0dHA6Ly9vY3NwLnN0YXJmaWVs
# ZHRlY2guY29tLzBIBggrBgEFBQcwAoY8aHR0cDovL2NybC5zdGFyZmllbGR0ZWNo
# LmNvbS9yZXBvc2l0b3J5L3NmX2lzc3VpbmdfY2EtZzIuY3J0MFQGA1UdHwRNMEsw
# SaBHoEWGQ2h0dHA6Ly9jcmwuc3RhcmZpZWxkdGVjaC5jb20vcmVwb3NpdG9yeS9t
# YXN0ZXJzdGFyZmllbGQyaXNzdWluZy5jcmwwUAYDVR0gBEkwRzBFBgtghkgBhv1u
# AQcXAjA2MDQGCCsGAQUFBwIBFihodHRwOi8vY3JsLnN0YXJmaWVsZHRlY2guY29t
# L3JlcG9zaXRvcnkvMA0GCSqGSIb3DQEBCwUAA4IBAQA4Pf90cACyj2vf+vYBwzlD
# 1DQg6ZZ8qQy4LvOSvlBz1mcTb0cR9FTUoyY40Y2KELo/VMY97rSUE3XeYiuCDdQS
# 9LCb2JlVF4m68aEFryeLqge7zvn039iYOw2icq5we8YuRd0JgCX338GSXPHHFdXX
# wz2pq/99uzoFczv86U3+usaG9tfYPg+hda1BIzCDPYS9YcqaqUgMAswM//VM4rX5
# TKfKiaWvfDSumRS4zAsQVHxeiov1ucfjnozIsPguFbO6wZDlfl/+kOMPnsmxD3HA
# cAb0LSVrgjdk6HR12SQKtOVhGtbXWQMUPpmK9Txqygmj17zMMdYlHwNwo9ZCUprM
# MYIE5jCCBOICAQEwgcIwgbQxCzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6b25h
# MRMwEQYDVQQHEwpTY290dHNkYWxlMRowGAYDVQQKExFHb0RhZGR5LmNvbSwgSW5j
# LjEtMCsGA1UECxMkaHR0cDovL2NlcnRzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkv
# MTMwMQYDVQQDEypHbyBEYWRkeSBTZWN1cmUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IC0gRzICCQCEdhgoYvfCGjANBglghkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3AgEM
# MQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQB
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCD3/eZQo21GScXt
# KqxuqSlrlhQr5BAaA23jBDs82irC6DANBgkqhkiG9w0BAQEFAASCAQAs1AfDkxTv
# kATTo0jUr8XUE64Ux5iAzIy/zo0xIeLyaG9RpibpK5z+ABTWLSD0qZXTIY+oesy+
# Zpqf7HOxV998n5+RGwIWAbWv2NisoymkZYHSw0gVl4RCLdBP2JpSoaBulIobQ7ft
# J6mKe3zhGvYJ3Ny6yYUZ8MtMyGYE1BDwcOFxe2boEdbOMN+ULD8d3AzEP0iq+NNp
# D9gTB/9ET8wunISuz5qdeUcAZ/+m8Mc2OpT2ldlWeLBcuwCPpcv9A2TgsCC/vQu5
# tISe25G9H7amH5lpGKBBx/fsHPGziMzv8u1Hfh+Tufm+gAbN7trAO18DEkkQpaEh
# MdzBbRyrf8PioYICbTCCAmkGCSqGSIb3DQEJBjGCAlowggJWAgEBMIHTMIHGMQsw
# CQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTETMBEGA1UEBxMKU2NvdHRzZGFs
# ZTElMCMGA1UEChMcU3RhcmZpZWxkIFRlY2hub2xvZ2llcywgSW5jLjEzMDEGA1UE
# CxMqaHR0cDovL2NlcnRzLnN0YXJmaWVsZHRlY2guY29tL3JlcG9zaXRvcnkvMTQw
# MgYDVQQDEytTdGFyZmllbGQgU2VjdXJlIENlcnRpZmljYXRlIEF1dGhvcml0eSAt
# IEcyAghX62vcgKuJTDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3
# DQEHATAcBgkqhkiG9w0BCQUxDxcNMTkwNDIzMTUxMjMwWjAjBgkqhkiG9w0BCQQx
# FgQUNQInJRk+JODtyUBsayoy4OwUoqgwDQYJKoZIhvcNAQEBBQAEggEAqKps9dAm
# GOZB6u13uxptKWxvO5t5+p3l/rMg/5+3gkDo/mu5x9KMwfazuIdln0QVCjbiniUi
# domZaxC87EZteiYT2PO1M+dHFoSyRrZyWyWvhVbejhc6SP4z1vV3IpB69Q2DUgYF
# Js8NwFrHBfE9IpTGStiM5BDI8v1lqBP8u4m55HcdeQqyiqsjKxpRfDxS6Cql3mrx
# l1rRjnBZ2+BIKMYIjtygC9EabhVxcg0HL7kj/hOwDc9nMjlla2cdNx0qwZKsZYwM
# zJi7j20mr9zFO3D4BAUmQOPXdxeVLGI8yyH/VqfMZdReRWTYVokidRP1bnMbAEnO
# PNkIGSAnTfh1aA==
# SIG # End signature block
