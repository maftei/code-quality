#!/usr/bin/env bash
set -euo pipefail

# Creates the code-quality structure IN THE CURRENT FOLDER (no extra nesting).

# --- top-level files ---
cat > pom.xml <<'EOF'
<project>
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.yourorg.quality</groupId>
  <artifactId>code-quality-parent</artifactId>
  <version>1.0.0</version>
  <packaging>pom</packaging>
  <modules>
    <module>checkstyle-config</module>
    <module>org-parent</module>
  </modules>
</project>
EOF

cat > README.md <<'EOF'
# code-quality

Centralized Checkstyle for all Java services.

## Local install
mvn -q -DskipTests install

## Use in a microservice (pom.xml)
<parent>
  <groupId>com.yourorg.build</groupId>
  <artifactId>org-parent</artifactId>
  <version>1.0.0</version>
  <relativePath/>
</parent>
EOF

cat > .editorconfig <<'EOF'
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.java]
indent_style = space
indent_size = 4
max_line_length = 120
EOF

cat > .gitignore <<'EOF'
target/
.idea/
*.iml
*.log
.DS_Store
EOF

# --- checkstyle-config module ---
mkdir -p checkstyle-config/src/main/resources/checkstyle

cat > checkstyle-config/pom.xml <<'EOF'
<project>
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.yourorg.quality</groupId>
  <artifactId>checkstyle-config</artifactId>
  <version>1.0.0</version>
  <packaging>jar</packaging>
  <name>YourOrg Checkstyle Config</name>
</project>
EOF

cat > checkstyle-config/src/main/resources/checkstyle/checkstyle.xml <<'EOF'
<!DOCTYPE module PUBLIC
    "-//Checkstyle//DTD Checkstyle Configuration 1.3//EN"
    "https://checkstyle.org/dtds/configuration_1_3.dtd">
<module name="Checker">
  <module name="SuppressWithPlainTextCommentFilter">
    <property name="offCommentFormat" value="CHECKSTYLE:OFF"/>
    <property name="onCommentFormat"  value="CHECKSTYLE:ON"/>
  </module>

  <module name="TreeWalker">
    <!-- Formatting -->
    <module name="Indentation">
      <property name="basicOffset" value="4"/>
      <property name="tabWidth" value="4"/>
    </module>
    <module name="LineLength">
      <property name="max" value="120"/>
      <property name="ignorePattern" value="^package|^import|http[s]?://"/>
    </module>
    <module name="NeedBraces"/>
    <module name="LeftCurly"><property name="option" value="eol"/></module>
    <module name="WhitespaceAfter"/>
    <module name="WhitespaceAround"/>

    <!-- Imports -->
    <module name="AvoidStarImport"/>
    <module name="UnusedImports"/>

    <!-- Naming -->
    <module name="TypeName"/>
    <module name="MethodName"/>
    <module name="ParameterName"/>
    <module name="ConstantName"/>

    <!-- Light Javadoc defaults -->
    <module name="JavadocType"/>
    <module name="JavadocMethod">
      <property name="scope" value="public"/>
      <property name="allowMissingPropertyJavadoc" value="true"/>
      <property name="allowMissingParamTags" value="true"/>
      <property name="allowMissingThrowsTags" value="true"/>
    </module>

    <!-- Best practices -->
    <module name="EmptyCatchBlock">
      <property name="exceptionVariableName" value="expected|ignore|ignored"/>
    </module>
    <module name="MagicNumber">
      <property name="ignoreNumbers" value="-1,0,1,2,3,4,5,6,7,8,9,10,100,1000"/>
      <property name="ignoreHashCodeMethod" value="true"/>
    </module>
  </module>
</module>
EOF

cat > checkstyle-config/src/main/resources/checkstyle/suppressions.xml <<'EOF'
<!DOCTYPE suppressions PUBLIC
    "-//Checkstyle//DTD SuppressionFilter Configuration 1.2//EN"
    "https://checkstyle.org/dtds/suppressions_1_2.dtd">
<suppressions>
  <!-- Example: suppress generated sources -->
  <suppress files=".+/generated/.+" checks=".*"/>
</suppressions>
EOF

# --- org-parent module ---
mkdir -p org-parent

cat > org-parent/pom.xml <<'EOF'
<project>
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.yourorg.build</groupId>
  <artifactId>org-parent</artifactId>
  <version>1.0.0</version>
  <packaging>pom</packaging>

  <properties>
    <maven.checkstyle.version>3.3.1</maven.checkstyle.version>
    <checkstyle.tool.version>10.17.0</checkstyle.tool.version>
  </properties>

  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>com.yourorg.quality</groupId>
        <artifactId>checkstyle-config</artifactId>
        <version>1.0.0</version>
      </dependency>
    </dependencies>
  </dependencyManagement>

  <build>
    <pluginManagement>
      <plugins>
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-checkstyle-plugin</artifactId>
          <version>${maven.checkstyle.version}</version>
          <dependencies>
            <!-- Pin Checkstyle engine -->
            <dependency>
              <groupId>com.puppycrawl.tools</groupId>
              <artifactId>checkstyle</artifactId>
              <version>${checkstyle.tool.version}</version>
            </dependency>
            <!-- Load our rules from classpath -->
            <dependency>
              <groupId>com.yourorg.quality</groupId>
              <artifactId>checkstyle-config</artifactId>
              <version>1.0.0</version>
            </dependency>
          </dependencies>
          <configuration>
            <configLocation>checkstyle/checkstyle.xml</configLocation>
            <suppressionsLocation>checkstyle/suppressions.xml</suppressionsLocation>
            <encoding>UTF-8</encoding>
            <consoleOutput>true</consoleOutput>
            <failsOnError>true</failsOnError>
            <includeTestSourceDirectory>true</includeTestSourceDirectory>
            <linkXRef>false</linkXRef>
          </configuration>
          <executions>
            <execution>
              <id>checkstyle-verify</id>
              <phase>verify</phase>
              <goals><goal>check</goal></goals>
            </execution>
          </executions>
        </plugin>
      </plugins>
    </pluginManagement>
  </build>
</project>
EOF

# --- GitHub Workflows ---
mkdir -p .github/workflows

cat > .github/workflows/checkstyle-reusable.yml <<'EOF'
name: org-checkstyle
on:
  workflow_call:

jobs:
  checkstyle:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "21"
          cache: maven
      - name: Verify (includes Checkstyle)
        run: mvn -B -DskipTests verify
EOF

cat > .github/workflows/release.yml <<'EOF'
name: release
on:
  push:
    tags:
      - "v*.*.*"

jobs:
  build-publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "21"
          cache: maven
          # Configure these if you add distributionManagement to POMs
          server-id: your-registry
          server-username: MAVEN_USERNAME
          server-password: MAVEN_PASSWORD
      - name: Build & Deploy
        run: mvn -B -DskipTests deploy
        env:
          MAVEN_USERNAME: ${{ secrets.MAVEN_USERNAME }}
          MAVEN_PASSWORD: ${{ secrets.MAVEN_PASSWORD }}
EOF

echo "✅ Structure created."
echo
echo "Next:"
echo "  1) mvn -q -DskipTests install"
echo "  2) In your microservice POM add the parent:"
echo "     <parent><groupId>com.yourorg.build</groupId><artifactId>org-parent</artifactId><version>1.0.0</version><relativePath/></parent>"
echo "  3) Run in the microservice: mvn -q -DskipTests verify"