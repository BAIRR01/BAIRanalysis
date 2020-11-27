#!/usr/bin/env python3

from os import environ
from zipfile import ZipFile, ZIP_DEFLATED
from tempfile import mkstemp
from pathlib import Path
from argparse import ArgumentParser
from logging import getLogger, StreamHandler, Formatter, INFO, DEBUG

from flywheel import Client, ApiException

lg = getLogger('upload_flywheel')


def upload_to_flywheel(fw, bids_dir, group_name, project_name, subject_to_upload=None):

    if subject_to_upload is not None:
        project = fw.resolve(f'{group_name}/{project_name}').path[-1]

    else:
        permissions = delete_project(fw, group_name, project_name)
        group = fw.get(group_name)
        project = group.add_project(label=project_name)

        for p in permissions:
            if p.id in [x.id for x in project.permissions]:
                continue  # exists already
            lg.debug(f'Permissions: setting {p.id} to {p.access}')
            project.add_permission(p)

    for f_subj in bids_dir.iterdir():
        if f_subj.is_file():
            if subject_to_upload is None or f_subj.stem == 'participants':
                lg.debug(f'Uploading {f_subj.relative_to(bids_dir)} to root directory')
                project.upload_file(f_subj)

        elif not f_subj.name.startswith('sub-'):  # f.e. stimuli folder
            lg.debug(f'Zipping and uploading {f_subj.relative_to(bids_dir)} to root directory')
            with temp_zip(f_subj) as zipped:
                project.upload_file(zipped)

        else:
            if subject_to_upload is not None and subject_to_upload != f_subj.name:
                lg.debug(f'Skipping subject {f_subj.name} because it is not {subject_to_upload}')
                continue

            lg.debug(f'Creating subject {f_subj.relative_to(bids_dir)}')
            subject = project.add_subject(label=f_subj.name)
            subject.update(label=f_subj.name)

            for f_sess in f_subj.iterdir():
                if f_sess.is_file():
                    lg.debug(f'Uploading {f_sess.relative_to(bids_dir)} to {f_subj.name}')
                    subject.upload_file(f_sess)

                elif not f_sess.name.startswith('ses-'):
                    lg.warning(f'Cannot upload {f_sess.relative_to(bids_dir)}')

                else:
                    lg.debug(f'Creating session {f_sess.relative_to(bids_dir)}')
                    session = subject.add_session(label=f_sess.name)
                    session.subject = f_subj.name   # a bug? How many times do we need to set a subject name???
                    for f_acq in f_sess.iterdir():
                        if f_acq.is_file():
                            lg.debug(f'Uploading {f_acq.relative_to(bids_dir)} to {f_sess.name}')
                            session.upload_file(f_acq)

                        else:
                            lg.debug(f'Creating acquisition {f_acq.relative_to(bids_dir)}')
                            acquisition = session.add_acquisition(label=f_acq.name)

                            for f_file in f_acq.iterdir():
                                if f_file.is_file():
                                    acquisition.upload_file(f_file)
                                    lg.debug(f'Uploading {f_file.relative_to(bids_dir)} to {f_acq.name}')

                                else:
                                    lg.warning(f'Cannot upload {f_file.relative_to(bids_dir)}. there should be no directories here')


def delete_project(fw, group_name, project_name):

    try:
        project = fw.resolve(f'{group_name}/{project_name}').path[-1]

    except ApiException:
        return []

    else:
        permissions = project.permissions
        lg.info(f'Deleting project {group_name}/{project_name}')
        fw.delete_project(project.id)
        return permissions


class temp_zip():
    def __init__(self, to_zip):
        self.to_zip = Path(to_zip).resolve()

    def __enter__(self):
        self.zipped = Path(mkstemp(suffix='.zip')[1])
        self.zipped.unlink()

        with ZipFile(self.zipped, 'w', compression=ZIP_DEFLATED) as zf:

            for to_zip in self.to_zip.iterdir():
                zf.write(to_zip, arcname=to_zip.relative_to(self.to_zip))

        return self.zipped

    def __exit__(self, type, value, traceback):
        self.zipped.unlink()


def main():

    parser = ArgumentParser(
        prog='flywheel',
        description="upload to flywheel")
    parser.add_argument(
        'bids_dir',
        help='Directory to upload')
    parser.add_argument(
        'project',
        help='Project name on flywheel (if it exists, it gets overwritten unless you pass --subject)')
    parser.add_argument(
        '--group',
        default='bair',
        help='Name of the Flywheel group')
    parser.add_argument(
        '--token',
        help='API token (by default, it uses the environmental variable FLYWHEEL_TOKEN)')
    parser.add_argument(
        '--subject',
        help='upload only the subject specified in this option (and the participants.tsv)')
    parser.add_argument(
        '-l', '--log', default='info',
        help='Logging level: info (default), debug')

    args = parser.parse_args()

    if args.log[:1].lower() == 'i':
        lg.setLevel(INFO)

    elif args.log[:1].lower() == 'd':
        lg.setLevel(DEBUG)

    formatter = Formatter(fmt='{message}', style='{')
    handler = StreamHandler()
    handler.setFormatter(formatter)

    lg.handlers = []
    lg.addHandler(handler)

    if args.token is not None:
        token = args.token
    else:
        token = environ['FLYWHEEL_TOKEN']
    fw = Client(token)
    bids_dir = Path(args.bids_dir).resolve()

    upload_to_flywheel(
        fw,
        bids_dir,
        args.group,
        args.project,
        args.subject,
        )


if __name__ == '__main__':
    main()