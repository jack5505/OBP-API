# How to Run OBP-API via IntelliJ IDEA

This guide walks you through importing, configuring, and running the OBP-API project inside IntelliJ IDEA.

---

## Prerequisites

| Requirement | Version |
|---|---|
| IntelliJ IDEA | 2022.1 or later (Community or Ultimate) |
| JDK | 11 (OpenJDK 11 recommended — see [jdk.java.net/archive](https://jdk.java.net/archive/)) |
| Maven | 3.6+ (bundled with IntelliJ or installed separately) |
| Scala plugin | Install from IntelliJ Marketplace (see below) |

---

## Step 1 — Install the Scala Plugin

1. Open IntelliJ IDEA.
2. Go to **File → Settings** (Windows/Linux) or **IntelliJ IDEA → Preferences** (macOS).
3. Select **Plugins → Marketplace**.
4. Search for **Scala** and install the JetBrains Scala plugin.
5. Restart IntelliJ IDEA when prompted.

---

## Step 2 — Import the Project

1. Choose **File → Open** and navigate to the root of the cloned `OBP-API` directory.
2. IntelliJ detects the `pom.xml` (Maven multi-module project). Select **Open as Maven Project** when prompted.
3. Wait for IntelliJ to index and download all dependencies (this may take several minutes on a first import).

---

## Step 3 — Set the Project JDK

1. Go to **File → Project Structure → Project**.
2. Set the **SDK** to JDK 11.  
   If JDK 11 is not listed, click **Add SDK → JDK** and point IntelliJ to your JDK 11 installation directory.
3. Set **Language level** to **11**.
4. Click **OK**.

---

## Step 4 — Configure Props File

OBP-API reads configuration from a props file at startup.

1. Copy the sample template:

   ```
   obp-api/src/main/resources/props/sample.props.template
   ```

   to a new file named:

   ```
   obp-api/src/main/resources/props/default.props
   ```

2. Open `default.props` and set at minimum:

   ```properties
   connector=star
   starConnector_supported_types=mapped,internal
   hostname=http://localhost:8080
   ```

3. **Database — PostgreSQL (recommended):**

   ```properties
   db.driver=org.postgresql.Driver
   db.url=jdbc:postgresql://localhost:5432/obpdb?user=obp&password=daniel.says
   ```

   > **Note:** `daniel.says` is the example password used throughout this project's documentation. Change it to a strong, unique password for any non-local deployment.

   Make sure the `obpdb` database exists and the `obp` user has full privileges (see the *Databases* section in the main [README](../../../../../README.md)).

4. **Database — H2 (quick start, no setup required):**

   ```properties
   db.driver=org.h2.Driver
   db.url=jdbc:h2:./lift_proto.db;NON_KEYWORDS=VALUE;DB_CLOSE_ON_EXIT=FALSE
   ```

---

## Step 5 — Create a Run Configuration

1. Go to **Run → Edit Configurations…**.
2. Click **+** and choose **Application**.
3. Fill in:

   | Field | Value |
   |---|---|
   | Name | `OBP-API` |
   | Module / JDK | Select the `obp-api` module; JDK 11 |
   | Main class | `bootstrap.http4s.Http4sServer` |
   | Working directory | Absolute path to the project root, e.g. `/home/you/OBP-API` |
   | VM options | See below |

4. **VM options** (paste the block below into the *VM options* field):

   ```
   -Xms1G -Xmx3G -Xss2m -XX:MaxMetaspaceSize=512m
   --add-opens=java.base/java.util=ALL-UNNAMED
   --add-opens=java.base/sun.security.util=ALL-UNNAMED
   --add-opens=java.base/java.lang.invoke=ALL-UNNAMED
   --add-opens=java.base/sun.reflect=ALL-UNNAMED
   --add-opens=java.base/java.lang=ALL-UNNAMED
   --add-opens=java.base/java.lang.reflect=ALL-UNNAMED
   --add-opens=java.base/java.security=ALL-UNNAMED
   --add-opens=java.base/java.util.jar=ALL-UNNAMED
   --add-opens=java.base/sun.nio.ch=ALL-UNNAMED
   --add-opens=java.base/java.nio=ALL-UNNAMED
   --add-opens=java.base/java.net=ALL-UNNAMED
   --add-opens=java.base/java.io=ALL-UNNAMED
   ```

5. Click **OK**.

---

## Step 6 — Build the Project

Before running, build the project to ensure all classes are compiled:

```
Build → Build Project   (Ctrl+F9 / ⌘F9)
```

If you see compilation errors related to the `obp-commons` module, first build that module:

```
Maven tool window → obp-commons → Lifecycle → install
```

Or from a terminal inside IntelliJ:

```sh
mvn install -pl .,obp-commons -DskipTests
```

---

## Step 7 — Run the Application

1. Select the `OBP-API` run configuration from the toolbar.
2. Click **Run** (Shift+F10 / ⌃R).
3. Watch the **Run** console. When you see a line like:

   ```
   Server started on http://localhost:8080
   ```

   the API is ready.

4. Open a browser or HTTP client and verify:

   ```
   http://localhost:8080/obp/v5.1.0/root
   ```

   You should receive a JSON response describing the API.

---

## Step 8 — Run Tests from IntelliJ

1. Create `obp-api/src/main/resources/props/test.default.props` (copy from `test.default.props.template`).
2. Ensure it contains at minimum:

   ```properties
   connector=star
   starConnector_supported_types=mapped,internal
   hostname=http://localhost:8016
   tests.port=8016
   ```

3. Right-click the test class or the `obp-api/src/test/scala/code` directory and choose **Run** or **Debug**.
4. For the run configuration add the same VM options listed in Step 5.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `InaccessibleObjectException` / `--add-opens` error | Add the `--add-opens` VM options listed in Step 5. |
| `OutOfMemoryError: Java heap space` | Increase `-Xmx`, e.g. `-Xmx4G`. |
| `OBP-00001: Hostname not specified` | Set `hostname=http://localhost:8080` in `default.props`. |
| `Could not connect to database` | Verify PostgreSQL is running and credentials in `default.props` are correct. |
| Scala sources show red after import | Go to **File → Invalidate Caches / Restart** and wait for re-indexing. |
| Maven dependencies not resolved | Open the **Maven** tool window and click the **Reload** button (circular arrows). |
