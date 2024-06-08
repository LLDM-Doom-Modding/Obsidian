# The script collects all of the translatable strings.
# Must be launched from the OBSIDIAN "/language" directory.

LOCALIZATIONDIR="language"
TEMPLATEFILENAME="TEMPLATE_Obsidian.po"

RESULTFILE="$LOCALIZATIONDIR/$TEMPLATEFILENAME"
INTERMEDFILE="$RESULTFILE.new"

if [[ ! -f $TEMPLATEFILENAME || `basename $(pwd)` != "$LOCALIZATIONDIR" ]]; then
	echo "This directory doesn't look like \"<OBSIDIAN_dir>/$LOCALIZATIONDIR/\". Make sure you launch the script in it."
	exit 1
fi

# Stop the script at the first error:
set -e

# Start to collect from the project root:
cd ..


echo Collecting strings...
grep -n -r -o "gui[.]gettext[(]\".*\"[)]" | sed -r {s/"^"/"#: "/} | sed -r {s/":_"/"\n"/} | sed -r {s/"\gui[.]gettext[(]"/"\nmsgid "/} | sed -r {s/"\)$"/"\nmsgstr \"\"\n"/} | sed -r {s/":$"/""/} > $INTERMEDFILE
grep -n -r -I -o "[_][(]\".*\"[)]" | sed -r {s/"^"/"#: "/} | sed -r {s/":_"/"\n"/} | sed -r {s/"\("/"msgid "/} | sed -r {s/"\)$"/"\nmsgstr \"\"\n"/} | sed -r {s/":$"/""/} >> $INTERMEDFILE

echo Removing unnecessary internal lines...
grep -n -B1 -A2 "\s\.\.\s" $INTERMEDFILE | sed -n 's/^\([0-9]\{1,\}\).*/\1d/p' | sed -f - $INTERMEDFILE -i

echo Removing duplicates...
cat $INTERMEDFILE | msguniq --no-wrap --use-first - -o "$INTERMEDFILE"

echo Writing to the $TEMPLATEFILENAME...
cat <<EOT > $RESULTFILE
# Language Translation for Obsidian.
# This file is put in the public domain.
# 
msgid ""
msgstr ""
"Project-Id-Version: Obsidian Level Maker\n"
"Report-Msgid-Bugs-To: \n"
"POT-Creation-Date: 2016-05-09 23:41+1000\n"
"PO-Revision-Date: $(date +'%Y-%m-%d %H:%M%z')\n"
"Last-Translator:  Dasho\n"
"Language-Team: English\n"
"Language: en_US\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
"Plural-Forms: nplurals=2; plural=(n != 1);\n"

# ################################################################################################################################################################################################## #
# Comments by Dashodanger: One can automate this process for each time the code is changed with the following nightmarish one-liners:                                                                #
# grep -n -r -o "gui[.]gettext[(]\".*\"[)]" | sed -r {s/"^"/"#: "/} | sed -r {s/":_"/"\n"/} | sed -r {s/"\gui[.]gettext[(]"/"\nmsgid "/} | sed -r {s/"\)$"/"\nmsgstr \"\"\n"/} | sed -r {s/":$"/""/} #
# grep -n -r -o "[_][(]\".*\"[)]" | sed -r {s/"^"/"#: "/} | sed -r {s/":_"/"\n"/} | sed -r {s/"\("/"msgid "/} | sed -r {s/"\)$"/"\nmsgstr \"\"\n"/} | sed -r {s/":$"/""/}                            #
# msguniq --no-wrap --use-first --escape <result file from above commands> -o <target PO file> (may need to use dos2unix depending on platform)                                                      #
# ################################################################################################################################################################################################## #
EOT

cat $INTERMEDFILE >> $RESULTFILE

rm $INTERMEDFILE

echo Done!