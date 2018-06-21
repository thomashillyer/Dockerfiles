# escape=`

FROM microsoft/dotnet-framework:4.7.2-runtime-windowsservercore-1709

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

#Install NuGet CLI
ENV NUGET_VERSION 4.4.1
RUN New-Item -Type Directory $Env:ProgramFiles\NuGet; `
    Invoke-WebRequest -UseBasicParsing https://dist.nuget.org/win-x86-commandline/v$Env:NUGET_VERSION/nuget.exe -OutFile $Env:ProgramFiles\NuGet\nuget.exe

# Install VS Test Agent
RUN Invoke-WebRequest -UseBasicParsing https://download.visualstudio.microsoft.com/download/pr/12210068/8a386d27295953ee79281fd1f1832e2d/vs_TestAgent.exe -OutFile vs_TestAgent.exe; `
    Start-Process vs_TestAgent.exe -ArgumentList '--quiet', '--norestart', '--nocache' -NoNewWindow -Wait; `
    Remove-Item -Force vs_TestAgent.exe; 
# Install VS Build Tools
RUN    Invoke-WebRequest -UseBasicParsing https://download.visualstudio.microsoft.com/download/pr/12210059/e64d79b40219aea618ce2fe10ebd5f0d/vs_BuildTools.exe -OutFile vs_BuildTools.exe; `
    # Installer won't detect DOTNET_SKIP_FIRST_TIME_EXPERIENCE if ENV is used, must use setx /M
    setx /M DOTNET_SKIP_FIRST_TIME_EXPERIENCE 1; `
    Start-Process vs_BuildTools.exe -ArgumentList `
    #Workloads
    '--add Microsoft.VisualStudio.Workload.MSBuildTools', `
    '--add Microsoft.VisualStudio.Workload.NetCoreBuildTools', `
    '--add Microsoft.VisualStudio.Workload.ManagedDesktopBuildTools', `
    #Optional?
    '--add Microsoft.Net.Component.3.5.DeveloperTools', `
    '--add Microsoft.Net.Component.4.TargetingPack', `
    '--add Microsoft.Net.Component.4.5.TargetingPack', `
    '--add Microsoft.Net.Component.4.5.1.TargetingPack', `
    '--add Microsoft.Net.Component.4.5.2.TargetingPack', `
    '--add Microsoft.Net.Component.4.6.TargetingPack', `
    '--add Microsoft.Net.Component.4.6.1.SDK', `
    '--add Microsoft.Net.Component.4.6.1.TargetingPack', `
    '--add Microsoft.VisualStudio.Component.NuGet.BuildTools', `
    '--add Microsoft.Net.Core.Component.SDK', `
    '--add Microsoft.NetCore.ComponentGroup.DevelopmentTools', `
    '--add Microsoft.NetCore.ComponentGroup.Web', `
    '--add Microsoft.VisualStudio.Component.TestTools.Core', `
    '--add Microsoft.Net.Core.Component.SDK.1x', `
    '--add Microsoft.Component.ClickOnce.MSBuild', `
    #Individual Components
    '--add Microsoft.VisualStudio.Component.Roslyn.Compiler', `
    '--add Microsoft.Component.MSBuild', `
    '--add Microsoft.VisualStudio.Component.Static.Analysis.Tools', `
    '--add Microsoft.VisualStudio.Component.TypeScript.2.8', `
    '--add Microsoft.VisualStudio.Component.AspNet45', `
    '--add Microsoft.Net.Component.4.6.2.SDK', `
    '--add Microsoft.Net.Component.4.6.2.TargetingPack', `
    '--add Microsoft.Net.Component.4.7.SDK', `
    '--add Microsoft.Net.Component.4.7.TargetingPack', `
    '--add Microsoft.Net.Component.4.7.1.SDK', `
    '--add Microsoft.Net.Component.4.7.1.TargetingPack', `
    '--add Microsoft.VisualStudio.Component.Node.Build', `
    '--add Microsoft.VisualStudio.Component.Node.Tools', `
    '--add Microsoft.VisualStudio.Component.NuGet', `
    '--add Microsoft.Component.NetFX.Native', `
    '--add Microsoft.VisualStudio.Component.TypeScript.2.0', `
    '--add Microsoft.VisualStudio.Component.TypeScript.2.1', `
    '--add Microsoft.VisualStudio.Component.TypeScript.2.2', `
    '--add Microsoft.VisualStudio.Component.TypeScript.2.3', `
    '--add Microsoft.VisualStudio.Component.TypeScript.2.5', `
    '--add Microsoft.VisualStudio.Component.TypeScript.2.6', `
    '--add Microsoft.VisualStudio.Component.TypeScript.2.7', `
    '--add Microsoft.VisualStudio.Component.TextTemplating', `
    #Known issues
    '--remove Microsoft.VisualStudio.Component.Windows10SDK.10240', `
    '--remove Microsoft.VisualStudio.Component.Windows10SDK.10586', `
    '--remove Microsoft.VisualStudio.Component.Windows10SDK.14393', `
    '--remove Microsoft.VisualStudio.Component.Windows81SDK', `
    '--quiet', '--wait', '--norestart', '--nocache' -NoNewWindow -Wait; `
    Remove-Item -Force vs_BuildTools.exe; `
    Remove-Item -Force -Recurse \"${Env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\"; `
    Remove-Item -Force -Recurse ${Env:TEMP}\*; `
    Remove-Item -Force -Recurse \"${Env:ProgramData}\Package Cache\"

# Install web targets
RUN Invoke-WebRequest -UseBasicParsing https://dotnetbinaries.blob.core.windows.net/dockerassets/MSBuild.Microsoft.VisualStudio.Web.targets.2018.05.zip -OutFile MSBuild.Microsoft.VisualStudio.Web.targets.zip;`
    Expand-Archive MSBuild.Microsoft.VisualStudio.Web.targets.zip -DestinationPath \"${Env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\BuildTools\MSBuild\Microsoft\VisualStudio\v15.0\" -Force; `
    Remove-Item -Force MSBuild.Microsoft.VisualStudio.Web.targets.zip

ENV ROSLYN_COMPILER_LOCATION "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\Roslyn"

# Set PATH in one layer to keep image size down.
RUN setx /M PATH $(${Env:PATH} `
    + \";${Env:ProgramFiles}\NuGet\" `
    + \";${Env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\TestAgent\Common7\IDE\CommonExtensions\Microsoft\TestWindow\" `
    + \";${Env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\")

# Install Targeting Packs
RUN @('4.0', '4.5.2', '4.6.2', '4.7.2') `
    | %{ `
        Invoke-WebRequest -UseBasicParsing https://dotnetbinaries.blob.core.windows.net/referenceassemblies/v${_}.zip -OutFile referenceassemblies.zip; `
        Expand-Archive referenceassemblies.zip -DestinationPath \"${Env:ProgramFiles(x86)}\Reference Assemblies\Microsoft\Framework\.NETFramework\" -Force; `
        Remove-Item -Force referenceassemblies.zip; `
    }

RUN powershell -Command `
    wget 'http://javadl.oracle.com/webapps/download/AutoDL?BundleId=210185' -Outfile 'C:\\jreinstaller.exe' ; `
    Start-Process -filepath C:\jreinstaller.exe -passthru -wait -argumentlist "/s,INSTALLDIR=c:\\Java\\jre1.8.0_91" ; `
    del C:\jreinstaller.exe

ENV JAVA_BIN C:\\Java\\jre1.8.0_91\\bin
RUN setx PATH %PATH%;${JAVA_BIN}

SHELL ["powershell.exe", "-ExecutionPolicy", "Bypass", "-Command"]
ARG SECRET

#Copy simplify
COPY ToCopy/ /

RUN Expand-Archive c:\MinGit.zip -DestinationPath c:\MinGit; `
    del c:\MinGit.zip; `
    $env:PATH = $env:PATH + 'C:\\MinGit\\cmd\\;C:\\MinGit\\cmd'; `
    Set-ItemProperty -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment\\' -Name Path -Value $env:PATH; `
    git config --global http.sslCAInfo C:/git_ssl/ca-bundle.crt

RUN expand-archive -Path 'C:\\tools.zip' -DestinationPath 'C:\\'; `
    del C:\\tools.zip;

RUN C:\tools\gacutil.exe /i C:/DLL/EntityFramework.dll; `
    C:\tools\gacutil.exe /i C:/DLL/EnvDTE.dll; `
    C:\tools\gacutil.exe /i C:/DLL/Microsoft.Data.Entity.Design.dll;

RUN powershell -NoProfile -ExecutionPolicy Bypass -Command .\install.ps1 ; `
    del .\\install.ps1 ;
RUN choco install -y nodejs.install 7zip.install

RUN ".\\silverlight_sdk.exe" ; `
    Get-ChildItem -Path 'C:\\Program Files (x86)\\MSBuild\\Microsoft\\Silverlight' -Recurse |  Move-Item -Destination 'C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\BuildTools\\MSBuild\\Microsoft\\' ;

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
RUN Start-Process 'C:\\WebDeploy_amd64_en-US.msi' '/qn' -PassThru | Wait-Process; `
    del C:\\WebDeploy_amd64_en-US.msi ; `
    del .\\silverlight_sdk.exe -Force;

RUN $path = $env:path + ';C:\Program Files (x86)\Microsoft SDKS\Typescript\2.8;'; Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\' -Name Path -Value $path

ENTRYPOINT ["C:\\Java\\jre1.8.0_91\\bin\\java.exe", "-jar", ".\\agent.jar"]
