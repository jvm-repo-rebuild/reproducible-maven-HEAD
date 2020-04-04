Rebuild Reproducibility Check for Apache Maven master HEAD
==========================================================

[```reproducible-central```](https://github.com/jvm-repo-rebuild/reproducible-central) gives as summary of artifacts in Central Repository that are reproducible, eventually partially.

This is great to spread the word once reproducibility work has been done for a public release, but
when reproducibility work has not yet been done, it's sad to discover the issue after having done
a release.

We need to check reproducibility of latest SNAPSHOT/master HEAD to identify issues before releasing.

## Results

<!-- BEGIN GENERATED CONTENT -->
| dist | groupId | artifactId | build | version | Reproducibility |
| ---- | ------- | ------------------ | ----- | ------- | --------------- |
| [shared](https://downloads.apache.org/maven/shared) | [org.apache.maven](https://repo.maven.apache.org/maven2/org/apache/maven) | [maven-archiver](https://repo.maven.apache.org/maven2/org/apache/maven/maven-archiver) | [spec](https://github.com/jvm-repo-rebuild/reproducible-maven-HEAD/tree/master/maven/shared/maven-archiver.buildspec) / [info](https://github.com/jvm-repo-rebuild/reproducible-maven-HEAD/tree/master/maven-archiver-3.5.1-SNAPSHOT.buildinfo) | 3.5.1-SNAPSHOT |  3 [:warning:](https://github.com/jvm-repo-rebuild/reproducible-maven-HEAD/tree/master/maven/shared/maven-archiver-*.buildinfo.compare) |
| [shared](https://downloads.apache.org/maven/shared) | [org.apache.maven.shared](https://repo.maven.apache.org/maven2/org/apache/maven/shared) | [maven-verifier](https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-verifier) | [spec](https://github.com/jvm-repo-rebuild/reproducible-maven-HEAD/tree/master/maven/shared/maven-verifier.buildspec) / [info](https://github.com/jvm-repo-rebuild/reproducible-maven-HEAD/tree/master/maven-verifier-1.7.2-SNAPSHOT.buildinfo) | 1.7.2-SNAPSHOT | 3 :heavy_check_mark: |
<!-- END GENERATED CONTENT -->
