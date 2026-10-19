
<%@ WebHandler Language="C#" Class="PositionsHandler" %>

using System;
using System.IO;
using System.Web;
using System.Web.Script.Serialization;
using System.Collections.Generic;
using System.Text.RegularExpressions;

public class PositionsHandler : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
        context.Response.Charset = "utf-8";

        // 职位文件所在文件夹（网站根目录下的 positions1）
        string folderPath = context.Server.MapPath("~/job/positions1/");

        var list = new List<object>();

        if (Directory.Exists(folderPath))
        {
            string[] allowedExt = { ".pdf", ".doc", ".docx", ".txt", ".md", ".html", ".htm" };

            foreach (string filePath in Directory.GetFiles(folderPath))
            {
                string ext = Path.GetExtension(filePath).ToLower();
                if (Array.IndexOf(allowedExt, ext) < 0) continue;

                string fileName = Path.GetFileName(filePath);
                string baseName = Path.GetFileNameWithoutExtension(filePath);

                // 命名规则：年(2)+月(2)+顺序(2)+字母(4)-职位名称-工作地
                // 例：260688GES-Sales Executive-Italy
                string posNo = "";
                string title = "";
                string location = "";
                DateTime fileDate = File.GetLastWriteTime(filePath);

                int firstDash = baseName.IndexOf('-');
                if (firstDash > 0)
                {
                    string posPart = baseName.Substring(0, firstDash).Trim();   // 260688GES
                    string rest = baseName.Substring(firstDash + 1).Trim();      // Sales Executive-Italy

                    int lastDash = rest.LastIndexOf('-');
                    if (lastDash > 0)
                    {
                        title = rest.Substring(0, lastDash).Trim();              // Sales Executive
                        location = rest.Substring(lastDash + 1).Trim();          // Italy
                    }
                    else
                    {
                        title = rest;
                        location = "";
                    }

                    posNo = posPart.ToUpper();

                    // 从 posNo 前 4 位解析年月，用于排序
                    var m = Regex.Match(posPart, @"^(\d{2})(\d{2})");
                    if (m.Success)
                    {
                        int yy = 2000 + int.Parse(m.Groups[1].Value);
                        int mm = int.Parse(m.Groups[2].Value);
                        if (mm >= 1 && mm <= 12)
                            fileDate = new DateTime(yy, mm, 1);
                    }
                }
                else
                {
                    // 不符合规则的文件名，原样显示，避免漏掉
                    posNo = baseName.ToUpper();
                    title = baseName;
                    location = "";
                }

                list.Add(new
                {
                    posNo       = posNo,
                    title       = title,
                    location    = location,
                    description = "Download",
                    dateStr     = fileDate.ToString("yyyy-MM"),
                    dateSort    = fileDate.Ticks / TimeSpan.TicksPerMillisecond,
                    fileName    = fileName,
                    filePath    = "positions1/" + fileName   // 前端点击的路径（相对）
                });
            }

            // 后端再按日期倒序排一遍，最新在前
            list.Sort((a, b) =>
            {
                dynamic da = a; dynamic db = b;
                return ((long)db.dateSort).CompareTo((long)da.dateSort);
            });
        }

        var serializer = new JavaScriptSerializer();
        context.Response.Write(serializer.Serialize(list));
    }

    public bool IsReusable { get { return false; } }
}