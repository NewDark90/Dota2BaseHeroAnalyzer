using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;

namespace BaseHeroAnalyzer.Core.Parsers
{
    public class ValveConfigParser
    {
        private Regex CommentRegex { get; set; } = new Regex(@"//.*\n");
        private Regex PropertyValueRegex { get; set; } = new Regex(@"""(?<prop>.*?)""(?<whitespace>\s+)""(?<val>.*?)""", RegexOptions.Singleline);

        public ValveConfigParser()
        {

        }

        public string ToJsonString(string config)
        {
            config = RemoveComments(config);
            config = ColonPropertyValues(config);
            
            return config;
        }

        public object ToJsonObject(string config)
        {
            return JsonConvert.DeserializeObject(ToJsonString(config));
        }

        private string RemoveComments(string config)
        {
            return CommentRegex.Replace(config, "");
        }

        private string ColonPropertyValues(string config)
        {
            return PropertyValueRegex.Replace(config, @"""${prop}"": ""${val}""");
        }
    }
}
