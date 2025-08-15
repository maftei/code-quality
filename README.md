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
