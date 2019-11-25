#! /usr/bin/env python

from os import environ, remove
from zipfile import ZipFile, ZIP_DEFLATED
import sys, pathlib, logging

from flywheel import Flywheel

GROUPID = 'bair'

# Setup logging--set our default level to debug
lg = logging.getLogger('xelo2bids')
lg.setLevel(logging.DEBUG)


def delete_flywheel_project(project_name):
    fw = Flywheel(environ['FLYWHEEL_TOKEN'])

    projectId = [x['_id'] for x in fw.get_all_projects() if x['label'] == project_name][0]
    lg.warning(f'Deleting project "{project_name}" with id {projectId}')
    permissions = fw.get_project(projectId)['permissions']
    sessions = [session['_id'] for session in fw.get_all_sessions() if session['project'] == projectId]

    for acq in fw.get_all_acquisitions():
        if acq['session'] in sessions:
            lg.debug(f'Deleting acquisition "{acq["label"]}"')
            fw.delete_acquisition(acq['_id'])

    for session in fw.get_all_sessions():
        if session['project'] == projectId:
            lg.debug(f'Deleting session "{session["label"]}"')
            fw.delete_session(session['_id'])

    lg.debug(f'Deleting the whole project')
    fw.delete_project(projectId)

    return permissions

def find_project_id(project_name, permissions, fw=None):
    if fw is None: fw = Flywheel(environ['FLYWHEEL_TOKEN'])
    projects = [x['_id'] for x in fw.get_all_projects() if x['label'] == project_name]
    if len(projects) == 1:
        projectId = projects[0]
        lg.debug(f'Adding to data to project "{project_name}"')
    else:
        projectId = fw.add_project({'label': project_name, 'group': GROUPID})
        lg.debug(f'Creating project "{project_name}" to group "{GROUPID}"')
        for perm in permissions[1:]:
            fw.add_project_permission(projectId, perm)
    return projectId

def upload_subject_dir(path, project_name, permissions=None, fw=None, projectId=None):
    if permissions is None: permissions = []
    if fw is None: fw = Flywheel(environ['FLYWHEEL_TOKEN'])
    if projectId is None: projectId = find_project_id(project_name, permissions, fw=fw)
    path = pathlib.Path(path)
    subjectId = {
        'code': path.name[4:],
        '_id': None,
    }
    for session in path.iterdir():
        if session.is_file():
            lg.warning(f'It is probably better to only upload inside session, so skip {session}')
            continue
        # a weird way because first you generate the session, which gives you the subject_id.
        # then you reuse the same subject_id across session
        info = {
            'label': session.name,
            'project': projectId,
            }
        if subjectId['_id'] is not None:
            info['subject'] = subjectId

        sessionId = fw.add_session(info)
        if subjectId['_id'] is None:
            subjectId['_id'] = fw.get_session(sessionId)['subject']['_id']
            fw.modify_session(sessionId, {'subject': subjectId})
        for acquisition in session.iterdir():
            if acquisition.is_file():
                lg.warning(f'Uploading file {acquisition.name} from {session} as attachment')
                fw.upload_file_to_project(projectId, str(acquisition))
                continue
            acquisitionId = fw.add_acquisition({
                'label': acquisition.name,
                'session': sessionId,
                })
            for filepath in acquisition.iterdir():
                lg.debug(f'Uploading {filepath.name} to {path.name}/{session.name}/{acquisition.name}')
                if filepath.suffix in ('.vhdr', '.vmrk'):
                    continue
                #if filepath.suffix == '.eeg':
                #    _zip_and_upload(filepath, fw, acquisitionId)
                #    continue
                fw.upload_file_to_acquisition(
                    acquisitionId, str(filepath))


def upload_project_dir(bids_root, project_name, permissions=None, fw=None):
    if permissions is None: permissions = []
    if fw is None: fw = Flywheel(environ['FLYWHEEL_TOKEN'])
    projectId = find_project_id(project_name, permissions, fw=fw)
    bids_root = pathlib.Path(bids_root)
    for extra in bids_root.iterdir():
        if extra.is_file():
            fw.upload_file_to_project(projectId, str(extra))
            continue

        if not extra.name.startswith('sub-'):
            lg.debug(f'Uploading directory {extra.name} as zipped file')
            _zip_and_upload(extra, fw, projectId)
            continue
        else:
            upload_subject_dir(extra, project_name, projectID=projectID, fw=fw,
                               permissions=permissions)


def _zip_and_upload(file_or_dir, fw, projectId):

    zipped_file = file_or_dir.parent / (file_or_dir.name + '.zip')

    with ZipFile(zipped_file, 'w', compression=ZIP_DEFLATED) as zf:

        if file_or_dir.suffix == '.eeg':

            for SUFFIX in ('.eeg', '.vmrk', '.vhdr'):
                to_zip = file_or_dir.with_suffix(SUFFIX)
                zf.write(to_zip, arcname=to_zip.name)

        else:
            for to_zip in file_or_dir.iterdir():
                zf.write(to_zip, arcname=to_zip.name)

    if file_or_dir.suffix == '.eeg':
        fw.upload_file_to_acquisition(projectId, str(zipped_file))
    else:
        fw.upload_file_to_project(projectId, str(zipped_file))

    remove(str(zipped_file))


# script stuff:
if 'FLYWHEEL_TOKEN' not in environ:
    print("FLYWHEEL_TOKEN not defined in environment!")
    sys.exit(1)

(patharg, projarg, subjarg) = (None, None, None)
for arg in sys.argv[1:]: # skip the first arg (script invocation)
    if   arg == "-s" or arg == "--subject": subjarg = True
    elif patharg is None:                   patharg = arg
    elif projarg is None:                   projarg = arg
    else:
        print("SYNTAX: upload_to_flywheel.py <BIDS_path> <project_name>")
        sys.exit(1)
if subjarg:
    print("Uploading single subject directory %s to project %s" % (patharg, projarg))
    upload_subject_dir(patharg, projarg)
else:
    print("Uploading project directory %s to project %s" % (patharg, projarg))
    upload_project_dir(patharg, projarg)

print("Upload complete.")
sys.exit(0)

