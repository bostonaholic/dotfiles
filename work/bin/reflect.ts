import { exec } from "child_process";
import { promisify } from "util";
import fs from "fs/promises";

const execPromise = promisify(exec);

interface Item {
  title: string;
  body: string;
  closedAt: string;
}

async function fetchMergedPRsAndIssues(): Promise<void> {
  const dateRange = `$(date -v-6m +%Y-%m-%d)..$(date +%Y-%m-%d)`;
  const baseCommand = `--author bostonaholic --limit 1000 --json title,body,closedAt `;
  
  const prCommand = `gh search prs ${baseCommand} --merged true --merged-at ${dateRange}`;
  const issueCommand = `gh search issues ${baseCommand} --created ${dateRange}`;

  try {
    const [prResult, issueResult] = await Promise.all([
      execPromise(prCommand),
      execPromise(issueCommand)
    ]);

    if (prResult.stderr) console.error("PR Error:", prResult.stderr);
    if (issueResult.stderr) console.error("Issue Error:", issueResult.stderr);

    const prs: Item[] = JSON.parse(prResult.stdout);
    const issues: Item[] = JSON.parse(issueResult.stdout);

    // Generate markdown content
    let markdownContent = "# Merged Pull Requests and Closed Issues\n\n";
    
    [...prs, ...issues].sort((a, b) => new Date(b.closedAt).getTime() - new Date(a.closedAt).getTime())
      .forEach((item) => {
        markdownContent += `## ${item.title}\n`;
        markdownContent += `Closed at: ${item.closedAt}\n\n`;
        markdownContent += `${item.body}\n\n`;
        markdownContent += "---\n\n";
      });

    // Write to file
    await fs.writeFile("merged_prs_and_issues.md", markdownContent);
    console.log("Markdown file generated: merged_prs_and_issues.md");
  } catch (error) {
    console.error("Execution error:", error);
  }
}

fetchMergedPRsAndIssues();
