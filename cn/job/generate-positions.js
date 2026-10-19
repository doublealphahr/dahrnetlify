// job/generate-positions.js
// 用法：在 job/ 目录下执行  node generate-positions.js
const fs = require('fs');
const path = require('path');

const folder = path.join(__dirname, 'positions1');
const allowedExt = ['.pdf', '.doc', '.docx', '.txt', '.md', '.html', '.htm'];
const list = [];

if (fs.existsSync(folder)) {
    fs.readdirSync(folder).forEach(fileName => {
        const ext = path.extname(fileName).toLowerCase();
        if (!allowedExt.includes(ext)) return;

        const baseName = path.basename(fileName, ext);
        let posNo = '', title = '', location = '';

        const firstDash = baseName.indexOf('-');
        if (firstDash > 0) {
            const posPart = baseName.substring(0, firstDash).trim();
            const rest = baseName.substring(firstDash + 1).trim();
            const lastDash = rest.lastIndexOf('-');
            if (lastDash > 0) {
                title = rest.substring(0, lastDash).trim();
                location = rest.substring(lastDash + 1).trim();
            } else {
                title = rest;
            }
            posNo = posPart.toUpperCase();
        } else {
            posNo = baseName.toUpperCase();
            title = baseName;
        }

        // 从 posNo 前 4 位解析年月：2606 → 2026-06
        let dateStr = '';
        let dateSort = 0;
        const m = posNo.match(/^(\d{2})(\d{2})/);
        if (m) {
            const yy = 2000 + parseInt(m[1], 10);
            const mm = parseInt(m[2], 10);
            if (mm >= 1 && mm <= 12) {
                dateStr = `${yy}-${String(mm).padStart(2, '0')}`;
                dateSort = new Date(yy, mm - 1, 1).getTime();
            }
        }

        list.push({
            posNo,
            title,
            location,
            description: 'Download',
            dateStr,
            dateSort,
            fileName,
            filePath: 'positions1/' + fileName
        });
    });

    // 按日期倒序，最新在前
    list.sort((a, b) => b.dateSort - a.dateSort);
}

fs.writeFileSync(
    path.join(__dirname, 'positions.json'),
    JSON.stringify(list, null, 2),
    'utf-8'
);

console.log(`✅ Generated positions.json with ${list.length} position(s).`);