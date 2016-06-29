$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\main.ps1"
 

Describe -Tags "HealthCheck" "HealthCheck Results" {
 
    It "Checking health check All results" {
       CheckResult | Should Be "All True"
    }
    It "TotalScoreIncludingIgnoredChecks results" {
       CheckIndividualResult -Result0 74.28 | Should Be $true
    }
    It "memory_physical_memory_pressure results" {
       CheckIndividualResult -Result1 100| Should Be $true
    }
    It "memory_adhoc_workload_configuration results" {
       CheckIndividualResult -Result2 100| Should Be $true
    }
    It "security_password_policy results" {
       CheckIndividualResult -Result3 90| Should Be $true
    }
    It "security_guest_access results" {
       CheckIndividualResult -Result4 100| Should Be $true
    }
    It "dr_backup results" {
       CheckIndividualResult -Result5 0| Should Be $true
    }
    It "dr_simple_recovery_model results" {
       CheckIndividualResult -Result6 100| Should Be $true
    }
    It "configuration_database_compatibility_level results" {
       CheckIndividualResult -Result7 100| Should Be $true
    }
}
